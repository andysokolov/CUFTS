package CUFTS::CRDB4::Controller::Account;
use Moose;
use namespace::autoclean;

use CUFTS::CJDB::Authentication::LDAP;

use String::Util qw(hascontent trim);

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

CUFTS::CRDB4::Controller::Account - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut



sub base :Chained('../site') :PathPart('account') :CaptureArgs(0) {
    my ( $self, $c ) = @_;
}


sub logout :Chained('base') :PathPart('logout') :Args(0) {
    my ($self, $c) = @_;

    delete $c->session->{ $c->site->id }->{current_account_id};
    $c->clear_account;

	$c->redirect( $c->uri_for_site( $c->controller('Root')->action_for('site_index') ) );
}


sub login :Chained('base') :PathPart('login') :Args(0) {
    my ( $self, $c ) = @_;

    if ( $c->req->params->{login_key} || $c->req->params->{login_password} ) {

    	my $key      = trim( $c->req->params->{login_key} );
    	my $password = trim( $c->req->params->{login_password} );
    	my $site     = $c->site;

        if ( hascontent($key) ) {

            my $account;

            if ( hascontent($site->cjdb_authentication_module) ) {
                # Get our internal record, then check external system for password

                $account = $site->cjdb_accounts->find({ key => $key });
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
                $account = $site->cjdb_accounts->find({ key => $key, password => $crypted_pass });
            }

            if ( defined($account) ) {

                if ( $account->active ) {
                    $c->account($account);
                    $c->session->{ $site->id }->{current_account_id} = $account->id;
					$c->redirect( $c->uri_for_site( $c->controller('Root')->action_for('site_index') ) );
                }
                else {
                    push @{$c->stash->{error}}, $c->loc('This account has been disabled by library administrators.');
                }

            } else {
                push @{$c->stash->{error}}, $c->loc('The password or account was not recognized. Please check that you have entered the correct login name and password. If you are still having problems, please contact your administrator.');
            }
        }
    }

    $c->stash->{template} = 'login.tt';
}




sub manage :Chained('base') :PathPart('manage') :Args(0) {
    my ($self, $c) = @_;

    $c->has_account or
        return $c->redirect( $c->uri_for_site( $c->controller('Browse')->action_for('browse') ) );

    $c->stash->{template} = 'account_manage.tt';

    if ( defined($c->req->params->{save}) ) {

        if ( !hascontent($c->req->params->{name}) ) {
            push @{$c->stash->{error}}, $c->loc('Name is a required field.');
        }
        if ( !hascontent($c->req->params->{email}) ) {
            push @{$c->stash->{error}}, $c->loc('Email is a required field.');
        }

        my ($password, $password2) = ($c->req->params->{password}, $c->req->params->{password2});

        if ( hascontent($password) || hascontent($password2) ) {
            if ($password eq $password2) {
                $c->account->password(crypt($password, $c->account->key));
            } else {
                push @{$c->stash->{error}}, $c->loc('Passwords do not match.');
            }
        }

        $c->account->name(  trim($c->req->params->{name}) );
        $c->account->email( trim($c->req->params->{email}) );

        if ( !defined($c->stash->{error}) ) {
            $c->account->update;
            $c->stash->{results} = $c->loc('Updated account settings.');
        }

    }
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
