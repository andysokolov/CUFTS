package CUFTS::MaintTool4::Controller::Admin::Accounts;
use Moose;
use namespace::autoclean;

use String::Util qw(trim hascontent);

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

CUFTS::MaintTool4::Controller::Admin::Accounts - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


sub base :Chained('/loggedin') :PathPart('account') :CaptureArgs(0) {
    my ( $self, $c ) = @_;

    if ( !$c->user->administrator ) {
        die( $c->loc('Administrator access required') );
    }
}

sub load_account :Chained('base') :PathPart('') CaptureArgs(1) {
    my ( $self, $c, $account_id ) = @_;

    if ( $account_id ne 'new' ) {
        $c->stash->{account} = $c->model('CUFTS::Accounts')->find({ id => $account_id });
        if ( !defined $c->stash->{account} ) {
            die( $c->loc('Unable to find account id: ') . $account_id );
            $c->detach;
        }
    }
}


sub list :Chained('base') :PathPart('') :Args(0) {
    my ( $self, $c ) = @_;

    $c->form({
            optional         => [ qw( filter apply_filter page ) ],
            filters          => ['trim'],
    });

    if ( $c->form->valid->{apply_filter} ) {
        $c->session->{admin_accounts_filter} = $c->form->valid->{filter};
    }

    my %search;

    # Filter by name or provider
    if ( my $filter =  $c->session->{admin_accounts_filter} ) {
        $filter =~ s/([%_])/\\$1/g;
        $filter =~ s#\\#\\\\\\\\#;
        $search{-or} = {
            name => { ilike => "\%$filter\%" },
            key  => { ilike => "\%$filter\%" },
        };
    }

    my %search_options = (
        order_by  => ['name'],
        page      => int( $c->form->valid('page') || 1 ),
        rows      => 30
    );

    my $accounts_rs = $c->model('CUFTS::Accounts')->search( \%search, \%search_options );

    $c->stash->{page}           = $c->form->valid('page');
    $c->stash->{filter}         = $c->session->{admin_accounts_filter};
    $c->stash->{accounts_rs}    = $accounts_rs;
    $c->stash->{template}       = 'admin/accounts/list.tt';
}

sub edit :Chained('load_account') :PathPart('edit') :Args(0) {
    my ( $self, $c ) = @_;

    my $account = $c->stash->{account};

    my $form_validate = {
        required => [ qw( key name email  )],
        optional => [ qw( phone submit active edit_global journal_auth administrator account_sites admin_ac_page ) ],
        filters  => [ 'trim' ],
        dependency_groups => { password => [ 'password', 'verify_password' ] },
        constraints       => {
            password => {
                constraint => sub { $_[0] eq $_[1] },
                params => [ 'password', 'verify_password' ],
            },
        },
        defaults => {
            active        => 'false',
            edit_global   => 'false',
            administrator => 'false',
            journal_auth  => 'false',
        },
        missing_optional_valid => 1,
    };

    $c->stash->{field_messages} = {
        password => $c->loc('Passwords must match.')
    };

    if ( $c->has_param('submit') ) {

        $c->form($form_validate);
        $c->stash_params();

        my $new_account = 0;
        unless ( $c->form_has_errors ) {

            # Set the 'password' field to the crypted value before saving if it is set
            if ( hascontent( $c->form->valid('password') ) ) {
                $c->form->valid( 'password', crypt($c->form->valid('password'), $c->user->key) );
            }

            if ( ( !defined $account || $c->form->valid->{key} ne $account->key ) && $c->model('CUFTS::Accounts')->find({ key => $c->form->valid->{key} }) ) {
                $c->stash_errors( $c->loc('An account with this key already exists.') );
            }
            else {
                eval {
                    if ( defined $account ) {
                        $account->update_from_fv( $c->form );
                    }
                    else {
                        $account = $c->model('CUFTS::Accounts')->create_from_fv($c->form);
                        $new_account = 1;
                    }
                };
                if ($@) {
                    $c->stash_errors($@);
                }
                else {
                    if ( $new_account ) {
                        $c->flash_results( $c->loc('Account created.') );
                        return $c->redirect( $c->uri_for( $c->controller('Admin::Accounts')->action_for('edit'), [ $account->id ] ) );
                    }
                    delete $c->stash->{params}; # Use the updated record instead of any saved parameters
                    $c->stash_results( $c->loc('Account data updated.') );
                }
            }


        }
    }

    $c->stash->{admin_ac_page} = $c->form->valid->{admin_ac_page};
    $c->stash->{account}       = $account;
    $c->stash->{template}      = 'admin/accounts/edit.tt';
}


sub delete :Chained('load_account') :PathPart('delete') :Args(0) {
    my ( $self, $c ) = @_;

    my $account = $c->stash->{account};

    if ( $c->req->params->{do_delete} ) {
        push @{$c->flash->{results}}, $c->loc('Deleted account: ') . $account->name;
        $account->delete;
        return $c->redirect( $c->uri_for( $c->controller('Admin::Accounts')->action_for('list'), { page => $c->req->params->{admin_ac_page} } ) );
    }

    $c->stash->{admin_ac_page} = $c->form->valid->{admin_ac_page};
    $c->stash->{template}      = 'admin/accounts/delete.tt';
}

sub associate_sites :Chained('load_account') :PathPart('associate_sites') :Args(0) {
    my ( $self, $c ) = @_;

    my $account = $c->stash->{account};

    my $form_validate = {
            optional => [ qw( submit page admin_ac_page ) ],
            optional_regexp  => qr/^(site|orig)_.+/,
            filters  => ['trim'],
    };

    my %search_options = (
        order_by  => ['name'],
        page      => int( $c->form->valid('page') || 1 ),
        rows      => 30
    );

    my $sites_rs = $c->model('CUFTS::Sites')->search(
        {
            active => 't',
        },
        \%search_options,
     );

    if ( $c->has_param('submit') ) {

        $c->form($form_validate);

        unless ( $c->form_has_errors ) {
            eval {
                $c->model('CUFTS')->txn_do( sub {
                    foreach my $param ( keys %{ $c->form->valid } ) {
                        next if $param !~ /^orig_(\d+)$/;
                        my $id = $1;
                        if ( ($c->form->valid($param) || 0) != ($c->form->valid("site_$id") || 0) ) {
                            if ( $c->form->valid("site_$id") ) {
                                $c->model('CUFTS::AccountsSites')->create({ site => $id, account => $account->id });
                                $c->stash_results( $c->loc('Added site: ') . $c->model('CUFTS::Sites')->find({ id => $id })->name );
                            }
                            else {
                                $c->model('CUFTS::AccountsSites')->search({ site => $id, account => $account->id })->delete();
                                $c->stash_results( $c->loc('Removed site: ') . $c->model('CUFTS::Sites')->find({ id => $id })->name );
                            }
                        }
                    }
                });
            };
            if ($@) {
                $c->stash_errors($@);
                delete $c->stash->{results};
            }
        }
    }

    $c->stash->{active_sites}  = { map { $_->id => 1 } $account->sites->all };
    $c->stash->{admin_ac_page} = $c->form->valid->{admin_ac_page};
    $c->stash->{page}          = $c->form->valid->{page};
    $c->stash->{sites_rs}      = $sites_rs;
    $c->stash->{template}      = 'admin/accounts/associate.tt';
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
