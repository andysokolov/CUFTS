package CUFTS::CJDB::Controller::Account;
use Moose;
use namespace::autoclean;

use String::Util qw( trim hascontent );
use CUFTS::CJDB::Authentication::LDAP;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

CUFTS::CJDB::Controller::Account - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub base :Chained('../site') :PathPart('account') :CaptureArgs(0) {
    
}

sub logout :Chained('base') :PathPart('logout') :Args(0) {
    my ($self, $c) = @_;

    delete $c->session->{ $c->stash->{current_site}->id }->{current_account_id};
    delete $c->stash->{current_account};

    return $c->redirect_previous;
}

sub login :Chained('base') :PathPart('login') :Args(0) {
    my ( $self, $c ) = @_;

    if ( $c->req->params->{login} ) {

        $c->form({'required' => ['key', 'password'], 'optional' => 'login', 'filters' => ['trim']});

        if (defined($c->form->{valid}->{key})) {
            my $key      = $c->form->{valid}->{key};
            my $password = $c->form->{valid}->{password};
            my $site     = $c->stash->{current_site};
            my $account;


            if ( hascontent($site->cjdb_authentication_module) ) {
                # Get our internal record, then check external system for password

                $account = CJDB::DB::Accounts->search( site => $site->id, key => $key)->first;
                if ( defined($account) ) {
                    my $module = 'CUFTS::CJDB::Authentication::' . $site->cjdb_authentication_module;
                    eval {
                        $module->authenticate($site, $key, $password);
                    };
                    if ($@) {
                        # External validation error.
                        warn($@);
                        $account = undef;
                    }
                }
            }
            else {
                # Use internal authentication
                my $crypted_pass = crypt($password, $key);
                $account = CJDB::DB::Accounts->search( site => $site->id, key => $key, password => $crypted_pass)->first;
            }

            if ( defined($account) ) {

                if ( $account->active ) {
                    warn('!1!' . $c->session->{prev_uri});
                    $c->stash->{current_account} = $account;
                    $c->session->{ $c->stash->{current_site}->id }->{current_account_id} = $account->id;

                    return $c->redirect_previous;
                }
                else {
                    $c->stash->{error} = ['This account has been disabled by library administrators.'];
                }

            } else {
                $c->stash->{error} = ['The password or account was not recognized. Please check that you have entered the correct login name and password. If you are still having problems, please contact your administrator.'];
            }
        }        
    }


    $c->stash->{template} = 'login.tt';
}


sub create :Chained('base') :PathPart('create') :Args(0) {
    my ($self, $c) = @_;

    if (defined($c->req->params->{cancel})) {
        return $c->redirect_previous;
    }

    $c->stash->{template} = 'account_create.tt';

    if (defined($c->req->params->{key})) {

        $c->form({required => ['key', 'name', 'password', 'create'],
                  optional => ['email', 'password2'],
                  filters => ['trim']});

        my $site = $c->stash->{current_site};
        unless ($c->form->has_missing || $c->form->has_invalid || $c->form->has_unknown) {

            my $key       = $c->form->{valid}->{key};
            my $password  = $c->form->{valid}->{password};
            my $password2 = $c->form->{valid}->{password2};
            my $crypted_pass;
            my $level;

            my @accounts = CJDB::DB::Accounts->search('site' => $site->id, 'key' => $key);
            if (scalar(@accounts)) {
                push @{$c->stash->{error}}, "The user id '$key' already exists.";
                return;
            }

            if ( hascontent($site->cjdb_authentication_module) ) {
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
            
            my $account = CJDB::DB::Accounts->create({
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

            $c->session->{ $c->stash->{current_site}->id }->{current_account_id} = $account->id;
            $c->stash->{current_account} = $account;
            
            CJDB::DB::DBI->dbi_commit();

            return $c->redirect_previous;
        }
    } 
}


sub manage :Chained('base') :PathPart('manage') :Args(0) {
    my ($self, $c) = @_;

    # If the user logged out on this page, go back to /browse

    defined($c->stash->{current_account}) or
        return $c->redirect( $c->uri_for_site( $c->controller('Browse')->action_for('browse') ) );

    if (defined($c->req->params->{cancel})) {
        return $c->redirect_previous;
    }

    $c->stash->{template} = 'account_manage.tt';

    if (defined($c->req->params->{save})) {

        $c->form({required => ['name', 'email', 'save'],
                  optional => ['password', 'password2'],
                  filters => ['trim']});

        unless ($c->form->has_missing || $c->form->has_invalid || $c->form->has_unknown) {

            my ($password, $password2) = ($c->form->{valid}->{password}, $c->form->{valid}->{password2});

            if (defined($password) || defined($password2)) {
                if ($password eq $password2) {
                    $c->stash->{current_account}->password(crypt($password, $c->stash->{current_account}->key));
                } else {
                    push @{$c->stash->{error}}, "Passwords do not match.";
                    return;
                }
            }

            $c->stash->{current_account}->name($c->form->{valid}->{name});
            $c->stash->{current_account}->email($c->form->{valid}->{email});
            $c->stash->{current_account}->update;           
            
            CJDB::DB::DBI->dbi_commit();

            return $c->redirect_previous;
        }
    } 
}


sub tags :Chained('base') :PathPart('tags') :Args(0) {
    my ($self, $c) = @_;

    
    $c->stash->{tags} = CJDB::DB::Tags->get_mytags_list($c->stash->{current_account});
    $c->stash->{template} = 'mytags.tt';
}


=head1 AUTHOR

tholbroo

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
