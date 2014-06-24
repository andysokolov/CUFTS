package CUFTS::MaintTool4::Controller::Site::CJDB;
use Moose;
use namespace::autoclean;

use DateTime;
use String::Util qw( hascontent trim );

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

CUFTS::MaintTool4::Controller::Site::CJDB - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

use CUFTS::Util::Simple;

sub base :Chained('../base') :PathPart('cjdb') :CaptureArgs(0) {}

sub settings :Chained('base') :PathPart('settings') :Args(0) {
    my ( $self, $c ) = @_;

    my $form_settings_validate = {
        optional => [
            qw(
                submit

                cjdb_print_name
                cjdb_print_link_label

                cjdb_authentication_server
                cjdb_authentication_string1
                cjdb_authentication_string2
                cjdb_authentication_string3
                cjdb_authentication_level100
                cjdb_authentication_level50
            )
        ],
        required => [
            qw(
                cjdb_authentication_module
                cjdb_unified_journal_list
                cjdb_show_citations
                cjdb_display_db_name_only
            )
        ],
        filters                => ['trim'],
        missing_optional_valid => 1,
    };


    if ( $c->has_param('submit') ) {

        $c->form($form_settings_validate);
        $c->stash_params();

        unless ( $c->form_has_errors ) {

            eval { $c->site->update_from_fv($c->form); };
            if ($@) {
                $c->stash_errors($@);
            }
            else {
                $c->stash_results( $c->loc('CJDB settings updated.') );
                delete $c->stash->{params}; # Use the updated record instead of any saved parameters
            }
        }
    }

    $c->stash->{template} = 'site/cjdb/settings.tt';
}



my $form_data_validate_marc_settings = {
    optional => [
        qw(
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
            marc_settings
        )
    ],
    filters => ['trim'],
    missing_optional_valid => 1,
};

my $form_data_validate_rebuild = {
    optional => [
        qw(
            delete
            MARC
            rebuild
            rebuild_ejournals_only
            submit_rebuild
        )
    ],
    constraints => {
        delete  => qr/^[^&\|:;'"\\\/]+$/,
        MARC    => qr/^[^&\|:;'"\\\/]+$/,
    },
};

my $form_data_validate_delete_lccn = {
    required => [ qw( delete_lccn lccn_delete_submit ) ],
};

my $form_data_validate_upload_lccn = {
    required => [ qw( upload_lccn lccn_data_upload ) ],
};

my $form_data_validate_upload_data = {
    optional => [ qw( upload_label ) ],
    required => [ qw( upload_data cjdb_data_upload ) ],
    filters  => [ 'trim' ],
};

sub data :Chained('base') :PathPart('data') :Args(0) {
    my ( $self, $c ) = @_;

    $c->stash->{active_tab} = 'rebuild';
    my $upload_dir = $CUFTS::Config::CJDB_SITE_DATA_DIR . '/' . $c->site->id;

    if ( $c->has_param('marc_settings') ) {

        $c->stash->{active_tab} = 'export';
        $c->form($form_data_validate_marc_settings);
        $c->stash_params();

        unless ( $c->form_has_errors ) {
            eval { $c->site->update_from_fv($c->form); };
            if ($@) {
                $c->stash_errors($@);
            }
            else {
                $c->stash_results( $c->loc('CJDB MARC export settings updated.') );
            }
        }
    }
    elsif ( $c->has_param('lccn_delete_submit') ) {

        $c->stash->{active_tab} = 'lccn';
        $c->form($form_data_validate_delete_lccn);

        unless ( $c->form_has_errors ) {
            my $file = 'lccn_subjects';
            -e "$upload_dir/$file" and unlink "$upload_dir/$file"
                or die("Unable to unlink file '$file': $!");

            $c->stash_results( $c->loc( 'LCCN subject mapping file deleted' ) );
        }
    }
    elsif ( $c->has_param('submit_rebuild') ) {

        $c->stash->{active_tab} = 'rebuild';
        $c->form($form_data_validate_rebuild);

        unless ( $c->form_has_errors ) {

            my %delete = map { $_ => 1 } listref_to_list( $c->form->valid->{delete} );
            my @delete = keys %delete;

            my @rebuild = grep { !exists $delete{$_} } listref_to_list( $c->form->valid->{rebuild} );
            my @marc    = grep { !exists $delete{$_} } listref_to_list( $c->form->valid->{MARC} );

            if ( scalar @delete ) {
                foreach my $file (@delete) {
                    -e "$upload_dir/$file" and unlink "$upload_dir/$file"
                        or die("Unable to unlink file '$file': $!");
                }
                $c->stash_results( $c->loc('Files deleted: ') . join ', ', @delete );
            }

            if ( scalar @marc || scalar @rebuild || $c->form->valid->{rebuild_ejournals_only} ) {

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
                    $c->stash_results( $c->loc('CJDB rebuild job created: ') . $job->id );
                }
                else {
                    $c->stash_errors( $c->loc('A CJDB delete job already exists. Delete it before scheduleing another.') );
                }

            }
        }
    }
    elsif ( $c->has_param('upload_data') ) {

        $c->stash->{active_tab} = 'rebuild';
        $c->form($form_data_validate_upload_data);

        unless ( $c->form_has_errors ) {
            my $filename = $c->form->valid->{upload_label} || DateTime->now->iso8601;

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
                $c->stash_errors($@);
            }
            else {
                $c->stash_results( $c->loc('Uploaded data file.') );
            }
        }
    }
    elsif ( $c->has_param('upload_lccn') ) {

        $c->stash->{active_tab} = 'lccn';
        $c->form($form_data_validate_upload_lccn);

        unless ( $c->form_has_errors ) {
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

            $c->stash_results( $c->loc('Uploaded LCCN data file.') );
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

    my ( $previous_jobs, $previous_pager ) = $c->job_queue->list_jobs(
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
    $c->stash->{MARC_url} .= '/' if !$c->stash->{MARC_url} =~ m{/$};
    $c->stash->{MARC_url} .= $c->site->key . '/sites/' . $c->site->id . '/static/';

    $c->stash->{template} = 'site/cjdb/data.tt';
}

sub accounts :Chained('base') :BasePath('accounts') :Args(0) {
    my ( $self, $c ) = @_;

    my $form_validate = {
        required => [ qw (
                search_field
                search_value
                submit
        ) ],
        optional => [ qw( page ) ],
        filters => ['trim'],
    };

    if ( $c->has_param('submit') ) {

        $c->form($form_validate);

        unless ( $c->form_has_errors ) {

            my $search_value = $c->form->valid->{search_value};
            my $search_field = $c->form->valid->{search_field};

            $c->stash->{accounts_rs} = $c->model('CUFTS::CJDBAccounts')->search(
                {
                    $search_field => { ilike => "\%$search_value\%" },
                    site          => $c->site->id,
                },
                {
                    order_by => $search_field,
                    rows     => 30,
                    page     => $c->form->valid->{page} || 1,
                }
            );
        }
    }

    $c->stash->{page}         = $c->form->valid('page');
    $c->stash->{search_field} = $c->req->params->{search_field};
    $c->stash->{search_value} = $c->req->params->{search_value};
    $c->stash->{template}     = 'site/cjdb/accounts.tt';
}

sub account :Chained('base') :BasePath('account') :Args(1) {
    my ( $self, $c, $account_id ) = @_;

    my $form_validate = {
        required => [
            qw(
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
                staff
                edit_erm_records
            ),
        ],
        defaults => {
            active => 'false',
        },
        filters => ['trim'],
        missing_optional_valid => 1,
    };

    my @handled_roles = ( qw(
        edit_erm_records
        staff
    ) );

    my $account = $c->model('CUFTS::CJDBAccounts')->find($account_id);
    if ( $account->site->id != $c->site->id ) {
        die("Error: Attempting to access a user who is not associated with the current site.");
    }

    if ( $c->has_param('submit') ) {

        $c->form($form_validate);
        $c->stash_params();

        unless ( $c->form_has_errors ) {

            # Check for duplicate key

            if ( $c->form->valid->{key} ne $account->key ) {
                my $key_check = $c->model('CUFTS::CJDBAccounts')->search({
                    key  => $c->form->valid->{key},
                    site => $c->site->id,
                })->count;
                if ( $key_check ) {
                    $c->stash_errors( $c->loc('Login already in use for this site: ') . $c->form->valid->{key} );
                }
            }

            if ( !(defined $c->stash->{errors} && scalar @{$c->stash->{errors}}) ) {

                if ( hascontent( $c->form->valid->{new_password} ) ) {
                    $c->form->valid->{password} = crypt( $c->form->valid->{new_password}, $c->form->valid->{key} );
                }

                eval {

                    $c->model('CUFTS')->schema->txn_do( sub {

                        $account->update_from_fv( $c->form );

                        foreach my $role ( qw( staff edit_erm_records) ) {
                            if ( $c->form->valid->{$role} ) {
                                $account->add_role($role);
                            }
                            else {
                                $account->remove_role($role);
                            }
                        }

                    });

                };
                if ($@) {
                    $c->stash_errors($@);
                }
                else {
                    $c->stash_results($c->loc('CJDB account updated.') );
                    delete $c->stash->{params}; # Use the updated record instead of any saved parameters
                }
            }
        }
    }

    $c->stash->{account}       = $account;
    $c->stash->{tags}          = $account->tag_summary;
    $c->stash->{template}      = 'site/cjdb/account.tt';
}

# Converts a list to a list convertable hash { val => 1 }. Can take a listref or single value
sub listref_to_list {
    my $list = shift;
    return () if !defined $list;
    return ref($list) ? @$list : ($list);
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
