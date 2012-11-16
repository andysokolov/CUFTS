package CUFTS::CRDB::Controller::Account;

use strict;
use warnings;
use base 'Catalyst::Controller';

use CUFTS::CJDB::Authentication::LDAP;
use CUFTS::Util::Simple;
use Data::FormValidator;

=head1 NAME

CUFTS::CRDB::Controller::Account - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller for account management, login, logout, etc..

=head1 METHODS

=cut


=head2 index 

=cut


sub logout : Chained('/site') PathPart('logout') Args(0) {
    my ($self, $c) = @_;

    $c->logout();

    return $c->response->redirect( $c->flash->{return_to} || $c->uri_for_site( $c->controller('Root')->action_for('app_root') ) );
}


sub login : Chained('/site') PathPart('login') Args(0) {
    my ($self, $c) = @_;

    $c->form( {
        required => ['key', 'password', 'login'],
        optional => [ 'return_to' ],
        filters  => ['trim'],
    } );

    if (defined($c->form->{valid}->{key})) {
        my $key      = $c->form->{valid}->{key};
        my $password = $c->form->{valid}->{password};
        my $site_id  = $c->site->id;
        my $account;

        if ( not_empty_string($c->site->cjdb_authentication_module) ) {
            # Get our internal record, then check external system for password

            $account = $c->model('CJDB::Accounts')->search( { site => $site_id, key => $key } )->first();
            if ( defined($account) ) {
                my $module = 'CUFTS::CJDB::Authentication::' . $c->site->cjdb_authentication_module;
                eval {
                    $module->authenticate($c->site, $key, $password);
                };
                if ($@) {
                    # External validation error.
                    warn($@);
                    $account = undef;
                    $c->stash->{error} = ['The password or account was not recognized. Please check that you have entered the correct login name and password. If you are still having problems, please contact your administrator.'];
                }
                else {
                
                    # Preauthenticated realm does not need a password
                
                    if ( !$c->authenticate({ key => $key, site => $site_id }, 'preauthenticated') ) {
                        $c->stash->{error} = ['There was an error in the pre-authentication user lookup.'];
                    }
                }
                
                
            }
        }
        else {

            # Use internal authentication

            if ( !$c->authenticate({ key => $key, password => $password, site => $site_id }, 'internal') ) {
                $c->stash->{error} = ['The password or account was not recognized. Please check that you have entered the correct login name and password. If you are still having problems, please contact your administrator.'];
            }

        }
        
        if ( defined($c->user) ) {
            if ( $c->user->active ) {
                return $c->response->redirect( $c->flash->{return_to} || $c->uri_for_site( $c->controller('Root')->action_for('app_root') ) );
            }
            else {
                $c->stash->{error} = ['This account has been disabled by library administrators.'];
            }
        }
    } 
    
    $c->stash->{template} = 'login.tt';
}

sub create : Chained('/site') PathPart('create') Args(0) {
    my ($self, $c) = @_;

    $c->stash->{template} = 'account_create.tt';

    if (defined($c->req->params->{key})) {

        $c->form({required => ['key', 'name', 'password', 'create'],
                  optional => ['email', 'password2'],
                  filters  => ['trim']});

        my $site = $c->site;
        unless ($c->form->has_missing || $c->form->has_invalid || $c->form->has_unknown) {

            my $key       = $c->form->{valid}->{key};
            my $password  = $c->form->{valid}->{password};
            my $password2 = $c->form->{valid}->{password2};
            my $crypted_pass;
            my $level;

            my @accounts = $c->model('CJDB::Accounts')->search('site' => $site->id, 'key' => $key);
            if (scalar(@accounts)) {
                push @{$c->stash->{error}}, "The user id '$key' already exists.";
                return;
            }

            if ( not_empty_string($site->cjdb_authentication_module) ) {
                my $module = 'CUFTS::CJDB::Authentication::' . $site->cjdb_authentication_module;
                eval {
                    $level = $module->authenticate($site, $key, $password);
                };
                if ($@) {
                    # External validation error.
                    warn($@);
                    push @{$c->stash->{error}}, "Unable to authenticate user against external service.";
                    return;
                }
            }    
            else {
                # Use internal authentication

                if ($password ne $password2) {
                    push @{$c->stash->{error}}, "Passwords do not match.";
                    return;
                }

                $crypted_pass = crypt($password, $key);

            }
            
            my $account = $c->model('CJDB::Accounts')->create({
                site      => $site->id,
                name      => $c->form->{valid}->{name},
                email     => $c->form->{valid}->{email},
                key       => $key,
                password  => $crypted_pass,
                active    => 'true',
                level     => $level || 0,
                
            });


            if (!defined($account)) {
                push @{$c->stash->{error}}, "Error creating account.";
                return;
            }

            if ( !$c->authenticate({ key => $key, site => $site->id }, 'preauthenticated') ) {
                die('There was an error in the pre-authentication user lookup.');
            }
            
            return $c->response->redirect( $c->flash->{return_to} || $c->uri_for_site( $c->controller('Root')->action_for('app_root') ) );
        }
    } 
}


sub manage : Chained('/site') PathPart('manage') Args(0) {
    my ($self, $c) = @_;

    # If the user logged out on this page, go back to /browse

    defined($c->user) or
        return $c->redirect( $c->uri_for_site( $c->controller('Root')->action_for('app_root') ) );

    $c->stash->{return_to} = $c->req->params->{return_to};
    $c->stash->{template} = 'account_manage.tt';

    if (defined($c->req->params->{save})) {

        $c->form({required => ['name', 'email', 'save'],
                  optional => ['change_password', 'change_password2'],
                  filters  => ['trim']});

        unless ($c->form->has_missing || $c->form->has_invalid || $c->form->has_unknown) {

            my ($password, $password2) = ($c->form->{valid}->{change_password}, $c->form->{valid}->{change_password2});

            if (defined($password) || defined($password2)) {
                if ($password eq $password2) {
                    $c->user->password(crypt($password, $c->user->key));
                } else {
                    push @{$c->stash->{error}}, "Passwords do not match.";
                    return;
                }
            }

            $c->user->name($c->form->{valid}->{name});
            $c->user->email($c->form->{valid}->{email});
            $c->user->update;           

            return $c->response->redirect( $c->flash->{return_to} || $c->uri_for_site( $c->controller('Root')->action_for('app_root') ) );
        }
    } 
}


# sub tags : Local {
#     my ($self, $c) = @_;
# 
#     
#     $c->stash->{tags} = CJDB::DB::Tags->get_mytags_list($c->user);
#     $c->stash->{template} = 'mytags.tt';
# }


sub index : Private {
    my ( $self, $c ) = @_;

    $c->response->body('Matched CUFTS::CRDB::Controller::Account in Account.');
}


=head1 AUTHOR

Todd Holbrook

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
