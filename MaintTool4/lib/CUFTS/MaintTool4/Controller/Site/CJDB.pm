package CUFTS::MaintTool4::Controller::Site::CJDB;
use Moose;
use namespace::autoclean;

use String::Util qw( hascontent trim );

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

CUFTS::MaintTool4::Controller::Site::CJDB - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

use CUFTS::Util::Simple;

my @valid_states = ( 'active', 'sandbox' );
my @valid_types  = ( 'css',    'cjdb_template' );

my $form_settings_validate = {
    optional => [
        qw{
            submit

            cjdb_print_name
            cjdb_print_link_label

            cjdb_authentication_module
            cjdb_authentication_server
            cjdb_authentication_string1
            cjdb_authentication_string2
            cjdb_authentication_string3
            cjdb_authentication_level100
            cjdb_authentication_level50

            marc_dump_856_link_label
            marc_dump_duplicate_title_field
            marc_dump_cjdb_id_field
            marc_dump_cjdb_id_indicator1
            marc_dump_cjdb_id_indicator2
            marc_dump_cjdb_id_subfield
            marc_dump_holdings_field
            marc_dump_holdings_indicator1
            marc_dump_holdings_indicator2
            marc_dump_holdings_subfield
            marc_dump_medium_text
            marc_dump_direct_links
        }
    ],
    required => [
        qw(
            cjdb_unified_journal_list
            cjdb_show_citations
            cjdb_display_db_name_only
        )
    ],
    filters                => ['trim'],
    missing_optional_valid => 1,
};

my $form_data_validate = {
    optional => [
        qw(
            submit
            delete
            rebuild
            test
            delete_lccn
            MARC
            rebuild_ejournals_only
            upload_data
            cjdb_data_upload
            upload_label
            lccn_data_upload
            upload_lccn
        )
    ],
    dependency_groups => {
        'data_upload' => [ 'upload_data',      'cjdb_data_upload' ],
        'lccn_upload' => [ 'lccn_data_upload', 'upload_lccn' ],
    },
    constraints => {
        delete  => qr/^[^&\|:;'"\\\/]+$/,
        test    => qr/^[^&\|:;'"\\\/]+$/,
        rebuild => qr/^[^&\|:;'"\\\/]+$/,       #"
    },
    filters => ['trim'],
};

my $form_accounts_validate = {
    required => [
        qw (
            search_field
            search_value
            submit
        )
    ],
    filters => ['trim'],
};

my @handled_roles = ( qw(
    edit_erm_records
    staff
) );

my $form_account_validate = {
    required => [
        qw(
            id
            key
            name
            email
        )
    ],
    optional => [
        qw(
            new_password
            level
            active
            submit
        ),
        map { 'role-' . $_ } @handled_roles,
    ],
    defaults => {
        active => 'false',
    },
    missing_optional_valid => 1,
    filters                => ['trim'],
};

# sub settings :Chained('../base') :PathPart('cjdb_settings') :Args(0) {
#     my ( $self, $c ) = @_;
#
#     $c->form($form_settings_validate);
#
#     if ( hascontent($c->form->valid->{submit}) ) {
#         unless ( $c->form->has_missing || $c->form->has_invalid || $c->form->has_unknown ) {
#
#             eval { $c->site->update_from_fv($c->form); };
#             if ($@) {
#                 my $err = $@;
#                 die($err);
#             }
#
#             push @{ $c->stash->{results} }, 'Site data updated.';
#         }
#     }
#
#     $c->stash->{template} = 'site/cjdb_settings.tt';
# }


# Converts a list to a list convertable hash { val => 1 }. Can take a listref or single value
sub listref_to_list {
    my $list = shift;
    return () if !defined $list;
    return ref($list) ? @$list : ($list);
}

sub data :Chained('../base') :PathPart('cjdb/data') :Args(0) {
    my ( $self, $c ) = @_;

    my $upload_dir = $CUFTS::Config::CJDB_SITE_DATA_DIR . '/' . $c->site->id;

    if ( $c->req->params->{submit} ) {

        $c->stash->{form_submitted} = 1;
        $c->form($form_data_validate);
        unless ( $c->form->has_missing || $c->form->has_invalid || $c->form->has_unknown ) {

            my %delete = map { $_ => 1 } listref_to_list( $c->form->valid->{delete} );

            my @rebuild = grep { !exists $delete{$_} } listref_to_list( $c->form->valid->{rebuild} );
            my @marc    = grep { !exists $delete{$_} } listref_to_list( $c->form->valid->{MARC} );

            $c->form->valid->{delete_lccn}
                and $delete{lccn_subjects} = 1;

            my @delete = keys %delete;

            foreach my $file (@delete) {
                -e "$upload_dir/$file" and unlink "$upload_dir/$file"
                    or die("Unable to unlink file '$file': $!");
            }

            scalar @delete
                and push @{ $c->stash->{results} }, ( 'Files deleted: ' . ( join ', ', @delete ) );

            if ( scalar @rebuild || scalar @marc || $c->form->valid->{rebuild_ejournals_only} ) {

                my ( $jobs, $pager ) = $c->job_queue->list_jobs(
                    {
                        site_id => $c->site->id,
                        class   => 'cjdb rebuild',
                        status  => [ 'new', 'runnable', 'working' ],
                    }
                );

                if ( !scalar @$jobs ) {
                    my $data =   scalar @rebuild ? { marc_print      => \@rebuild }
                               : scalar @marc    ? { marc_electronic => \@marc }
                                                 : { electronic_only => 1 };

                    my $job = $c->job_queue->add_job({
                        info  => 'Rebuild CJDB',
                        type  => 'cjdb',
                        class => 'cjdb rebuild',
                        data  => $data,
                    });
                    push @{ $c->stash->{results} }, ( 'CJDB rebuild job created: ' . $job->id );
                }
                else {
                    push @{ $c->stash->{errors} }, ( 'A CJDB delete job already exists. Delete it before scheduleing another.' );
                }

            }

        }
    }
    elsif ( $c->req->params->{upload_data} ) {
        $c->form($form_data_validate);

        unless ( $c->form->has_missing || $c->form->has_invalid || $c->form->has_unknown )
        {
            my $filename = $c->form->valid->{upload_label};
            unless ($filename) {
                my ( $sec, $min, $hour, $mday, $mon, $year, $wday ) = localtime(time);
                $mon  += 1;
                $year += 1900;
                $filename = sprintf( "%04i%02i%02i_%02i-%02i-%02i", $year, $mon, $mday, $hour, $min, $sec );
            }

            -d $upload_dir
                or mkdir $upload_dir
                    or die("Unable to create site upload dir '$upload_dir': $!");

            -e "$upload_dir/$filename"
                and die("File already exists with label: $filename");

            $c->request->upload('cjdb_data_upload')->copy_to("$upload_dir/$filename")
                or die("Unable to copy uploaded file to:  ($upload_dir/$filename): $!");

            $c->site->rebuild_ejournals_only(undef);
            eval { $c->site->update };
            if ($@) {
                my $err = $@;
                CUFTS::DB::DBI->dbi_rollback;
                die($err);
            }

            push @{ $c->stash->{results} }, 'Uploaded data file.';
        }
    }
    elsif ( $c->req->params->{upload_lccn} ) {
        $c->form($form_data_validate);

        unless ( $c->form->has_missing || $c->form->has_invalid || $c->form->has_unknown ) {
            my $filename = 'lccn_subjects';

            -d $upload_dir
                or mkdir $upload_dir
                    or die("Unable to create site upload dir '$upload_dir': $!");

            if ( -e "$upload_dir/$filename" ) {
                unlink "$upload_dir/$filename"
                    or die("Unable to delete existing file: $!");
            }

            $c->request->upload('lccn_data_upload')->copy_to("$upload_dir/$filename")
                or die("Unable to copy uploaded file to:  ($upload_dir/$filename): $!");

            push @{ $c->stash->{results} }, 'Uploaded LCCN data file.';
        }
    }

    if ( -d $upload_dir && opendir FILES, $upload_dir ) {
        my @file_list = grep !/^lccn_subjects$/, grep !/^\./, readdir FILES;
        $c->stash->{print_files} = \@file_list;

        # Get print file sizes

        my ( @file_sizes, @file_timestamps );
        foreach my $file (@file_list) {
            my $file_size = -s "$upload_dir/$file";
            push @file_sizes, $file_size;

            my $mtime = ( stat "$upload_dir/$file" )[9];
            my ( $sec, $min, $hour, $mday, $mon, $year ) = localtime($mtime);
            push @file_timestamps, sprintf( "%04i-%02i-%02i %02i:%02i:%02i", ($year+1900), ($mon+1), $mday, $hour, $min, $sec );

        }
        $c->stash->{print_file_sizes}      = \@file_sizes;
        $c->stash->{print_file_timestamps} = \@file_timestamps;


        # Get the call number file information

        if ( -e "$upload_dir/lccn_subjects" ) {
            my $mtime = ( stat "$upload_dir/lccn_subjects" )[9];
            my ( $sec, $min, $hour, $mday, $mon, $year ) = localtime($mtime);
            $c->stash->{call_number_file} = sprintf( "%04i-%02i-%02i %02i:%02i:%02i", ($year+1900), ($mon+1), $mday, $hour, $min, $sec );
        }

    }

    my ( $upcoming_jobs, $upcoming_pager ) = $c->job_queue->list_jobs(
        {
            site_id => $c->site->id,
            class   => 'cjdb rebuild',
            status  => [ 'new', 'runnable', 'working' ],

        },
        {
            rows => 1,
        }
    );
    $c->stash->{upcoming_jobs} = $upcoming_jobs;

    my ( $previous_jobs, $previouspager ) = $c->job_queue->list_jobs(
        {
            site_id => $c->site->id,
            class   => 'cjdb rebuild',
            status  => { '!=' => [ '-and', 'new', 'runnable', 'working' ] },

        },
        {
            rows => 1,
        }
    );
    $c->stash->{previous_jobs} = $previous_jobs;


    $c->stash->{MARC_url} = $CUFTS::Config::CJDB_URL;
    if ( $c->stash->{MARC_url} !~ m{/$} ) {
        $c->stash->{MARC_url} .= '/';
    }

    $c->stash->{MARC_url} .= $c->site->key . '/sites/' . $c->site->id . '/static/';

    $c->stash->{template} = 'site/cjdb/data.tt';
}

sub accounts :Chained('../base') :BasePath('cjdb/accounts') :Args(0) {
    my ( $self, $c ) = @_;

    if ( $c->req->params->{submit} ) {
        $c->form($form_accounts_validate);
        unless ( $c->form->has_missing || $c->form->has_invalid || $c->form->has_unknown )
        {

            my $search_value = $c->form->valid->{search_value};
            my $search_field = $c->form->valid->{search_field};

            my @accounts = CJDB::DB::Accounts->search(
                {   $search_field => { ilike => "\%$search_value\%" },
                    site => $c->site->id,
                },
                { order_by => $search_field }
            );

            $c->stash->{accounts} = \@accounts;

        }
    }

    $c->stash->{search_field} = $c->req->params->{search_field};
    $c->stash->{search_value} = $c->req->params->{search_value};

    $c->stash->{header_section} = 'Site Settings : C*DB Accounts';
    $c->stash->{template}       = 'site/cjdb/accounts.tt';
}

sub account :Chained('../base') :BasePath('cjdb/account') :Args(1) {
    my ( $self, $c, $account_id ) = @_;

    my $account = CJDB::DB::Accounts->retrieve($account_id);
    if ( $account->site != $c->site->id ) {
        die("Error: Attempting to access a user who is not associated with the current site.");
    }

    if ( $c->req->params->{submit} ) {

        $c->form($form_account_validate);
        unless ( $c->form->has_missing || $c->form->has_invalid || $c->form->has_unknown ) {

            # Check for duplicate key

            if ( $c->form->valid->{key} != $account->key ) {
                my @key_check = CJDB::DB::Accounts->search(
                    {   key  => $c->form->valid->{key},
                        site => $c->site->id,
                    }
                );
                if ( scalar(@key_check) ) {
                    $c->stash->{errors} = [ 'Login "' . $c->form->valid->{key} . '" already in use for this site.' ];
                }
            }

            if ( !scalar( $c->stash->{errors} ) ) {

                if ( not_empty_string( $c->form->{valid}->{new_password} ) ) {
                    $c->form->{valid}->{password} = crypt( $c->form->{valid}->{new_password}, $c->form->{valid}->{key} );
                }

                eval {
                    $account->update_from_form( $c->form );

                    ##
                    ## Handle role updates
                    ##


                    # Build role id lookup table

                    my @role_objects = CJDB::DB::Roles->retrieve_all;
                    my %roles_map;
                    foreach my $role_object ( @role_objects ) {
                        $roles_map{$role_object->role} = $role_object->id;
                    }


                    foreach my $role ( @handled_roles ) {

                        my $role_id = $roles_map{$role};
                        if ( !defined($role_id) ) {
                            die("Attempting to process a role which does not exist in the database: $role");
                        }

                        if ( $c->form->{valid}->{"role-${role}"} ) {

                            # Add a role

                            CJDB::DB::AccountsRoles->find_or_create( {
                                role => $role_id,
                                account => $account_id
                            } );

                        }
                        else {

                            # Remove a role

                            CJDB::DB::AccountsRoles->search( {
                                role => $role_id,
                                account => $account_id
                            } )->delete_all;

                        }
                    }


                };
                if ($@) {
                    my $err = $@;
                    CUFTS::DB::DBI->dbi_rollback;
                    die($err);
                }
                CUFTS::DB::DBI->dbi_commit;
                push @{ $c->stash->{results} }, 'CJDB account updated.';
            }
        }
    }

    $c->stash->{account}        = $account;
    $c->stash->{tags}           = CJDB::DB::Tags->get_mytags_list($account_id);
    $c->stash->{header_section} = 'Site Settings : C*DB Accounts';
    $c->stash->{template}       = 'site/cjdb/account.tt';
}


=encoding utf8

=head1 AUTHOR

Todd Holbrook

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
