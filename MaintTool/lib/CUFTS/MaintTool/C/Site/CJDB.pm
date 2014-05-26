package CUFTS::MaintTool::C::Site::CJDB;

use strict;
use base 'Catalyst::Base';

use CJDB::DB::Accounts;
use CJDB::DB::Tags;

use CUFTS::Util::Simple;

my @valid_states = ( 'active', 'sandbox' );
my @valid_types  = ( 'css',    'cjdb_template' );

my $form_settings_validate = {
    optional => [
        qw{
            submit
            cancel

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
            cancel
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

sub settings : Local {
    my ( $self, $c ) = @_;

    $c->req->params->{cancel}
        and return $c->redirect('/site/edit');

    if ( $c->req->params->{submit} ) {
        $c->form($form_settings_validate);

        unless ( $c->form->has_missing || $c->form->has_invalid || $c->form->has_unknown ) {

            eval { $c->stash->{current_site}->update_from_form( $c->form ); };
            if ($@) {
                my $err = $@;
                CUFTS::DB::DBI->dbi_rollback;
                die($err);
            }

            CUFTS::DB::DBI->dbi_commit;
            push @{ $c->stash->{results} }, 'Site data updated.';
        }
    }

    $c->stash->{header_section} = 'Site Settings : CJDB Settings';
    $c->stash->{template}       = 'site/cjdb/settings.tt';
}

sub data : Local {
    my ( $self, $c ) = @_;

    $c->req->params->{cancel}
        and return $c->redirect('/site/edit');

    my $upload_dir = $CUFTS::Config::CJDB_SITE_DATA_DIR . '/' . $c->stash->{current_site}->id;

    if ( $c->req->params->{submit} ) {
        $c->form($form_data_validate);

        unless ( $c->form->has_missing || $c->form->has_invalid || $c->form->has_unknown ) {
            my ( %delete, %rebuild, %marc, %test );
            $c->form->valid->{delete}
                and %delete = map { $_, 1 }
                                ref( $c->form->valid->{delete} )
                                ? @{ $c->form->valid->{delete} }
                                : ( $c->form->valid->{delete} );
            $c->form->valid->{rebuild}
                and %rebuild = map { ( $_, 1 ) }
                                ref( $c->form->valid->{rebuild} )
                                ? @{ $c->form->valid->{rebuild} }
                                : ( $c->form->valid->{rebuild} );
            $c->form->valid->{MARC}
                and %marc = map { ( $_, 1 ) }
                                ref( $c->form->valid->{MARC} )
                                ? @{ $c->form->valid->{MARC} }
                                : ( $c->form->valid->{MARC} );
            $c->form->valid->{test}
                and %test = map { ( $_, 1 ) }
                                ref( $c->form->valid->{test} )
                                ? @{ $c->form->valid->{test} }
                                : ( $c->form->valid->{test} );

            # Remove items to be deleted from rebuild/test lists

            foreach my $key ( keys %delete ) {
                delete $rebuild{$key};
                delete $marc{$key};
                delete $test{$key};
            }

            $c->form->valid->{delete_lccn}
                and $delete{lccn_subjects} = 1;

            my @delete  = keys(%delete);
            my @rebuild = keys(%rebuild);
            my @test    = keys(%test);
            my @MARC    = keys(%marc);

            foreach my $file (@delete) {
                -e "$upload_dir/$file" and unlink "$upload_dir/$file"
                    or die("Unable to unlink file '$file': $!");
            }

            scalar(@delete)
                and push @{ $c->stash->{results} },
                ( 'Files deleted: ' . ( join ', ', @delete ) );

            $c->stash->{current_site}->rebuild_cjdb(undef);
            $c->stash->{current_site}->rebuild_MARC(undef);
            $c->stash->{current_site}->rebuild_ejournals_only(undef);

            if ( scalar(@rebuild) ) {
                $c->stash->{current_site}->rebuild_cjdb( join '|', @rebuild );
                push @{ $c->stash->{results} },
                    ( 'CJDB will be rebuilt using files: ' . ( join ', ', @rebuild ) );
            }
            if ( scalar(@MARC) ) {
                $c->stash->{current_site}->rebuild_MARC( join '|', @MARC );
                push @{ $c->stash->{results} }, ( 'CJDB will be rebuilt using files for MARC records only: ' . ( join ', ', @MARC ) );
            }

            if ( $c->form->valid->{rebuild_ejournals_only} ) {
                $c->stash->{current_site}->rebuild_ejournals_only(1);
                push @{ $c->stash->{results} }, 'CJDB will be rebuilt from CUFTS electronic journal data only.';
            }

            if ( scalar(@test) ) {
                $c->stash->{current_site}->test_MARC_file( join '|', @test );
                push @{ $c->stash->{results} }, ( 'Files to have MARC data tested: ' . ( join ', ', @test ) );
            }
            else {
                $c->stash->{current_site}->test_MARC_file(undef);
                push @{ $c->stash->{results} }, 'No files marked for MARC testing.';
            }

            eval { $c->stash->{current_site}->update };
            if ($@) {
                my $err = $@;
                CUFTS::DB::DBI->dbi_rollback;
                die($err);
            }

            CUFTS::DB::DBI->dbi_commit;
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

            $c->request->upload('cjdb_data_upload')
                ->copy_to("$upload_dir/$filename")
                or die("Unable to copy uploaded file to:  ($upload_dir/$filename): $!");

            $c->stash->{current_site}->rebuild_ejournals_only(undef);
            eval { $c->stash->{current_site}->update };
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

        unless ( $c->form->has_missing || $c->form->has_invalid || $c->form->has_unknown )
        {
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

        my @file_sizes;
        foreach my $file (@file_list) {
            my $file_size = -s "$upload_dir/$file";
            push @file_sizes, $file_size;
        }
        $c->stash->{print_file_sizes} = \@file_sizes;

        # Get the call number file information

        if ( -e "$upload_dir/lccn_subjects" ) {
            my $mtime = ( stat "$upload_dir/lccn_subjects" )[9];
            my ( $sec, $min, $hour, $mday, $mon, $year ) = localtime($mtime);
            $year += 1900;
            $mon++;
            $c->stash->{call_number_file} = sprintf( "%04i-%02i-%02i %02i:%02i:%02i", $year, $mon, $mday, $hour, $min, $sec );
        }

    }

    $c->stash->{MARC_url} = $CUFTS::Config::CJDB_URL;
    if ( $c->stash->{MARC_url} !~ m{/$} ) {
        $c->stash->{MARC_url} .= '/';
    }

    $c->stash->{MARC_url} .= $c->stash->{current_site}->key
        . '/sites/'
        . $c->stash->{current_site}->id
        . '/static/';

    $c->stash->{header_section} = 'Site Settings : CJDB Data';
    $c->stash->{template}       = 'site/cjdb/data.tt';
}

sub accounts : Local {
    my ( $self, $c ) = @_;

    if ( $c->req->params->{submit} ) {
        $c->form($form_accounts_validate);
        unless ( $c->form->has_missing || $c->form->has_invalid || $c->form->has_unknown )
        {

            my $search_value = $c->form->valid->{search_value};
            my $search_field = $c->form->valid->{search_field};

            my @accounts = CJDB::DB::Accounts->search(
                {   $search_field => { ilike => "\%$search_value\%" },
                    site => $c->stash->{current_site}->id,
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

sub account : Local {
    my ( $self, $c, $account_id ) = @_;

    my $account = CJDB::DB::Accounts->retrieve($account_id);
    if ( $account->site != $c->stash->{current_site}->id ) {
        die("Error: Attempting to access a user who is not associated with the current site.");
    }

    if ( $c->req->params->{submit} ) {

        $c->form($form_account_validate);
        unless ( $c->form->has_missing || $c->form->has_invalid || $c->form->has_unknown ) {

            # Check for duplicate key

            if ( $c->form->valid->{key} != $account->key ) {
                my @key_check = CJDB::DB::Accounts->search(
                    {   key  => $c->form->valid->{key},
                        site => $c->stash->{current_site}->id,
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

=head1 NAME

CUFTS::MaintTool::C::Site::CJDB - Component for CJDB related data

=head1 SYNOPSIS

Handles site editing, changing sites, etc.

=head1 DESCRIPTION

Handles site editing, changing sites, etc.

=head1 AUTHOR

Todd Holbrook

=head1 LICENSE

This library is free software . You can redistribute it and/or modify
it under the same terms as perl itself.

=cut

1;
