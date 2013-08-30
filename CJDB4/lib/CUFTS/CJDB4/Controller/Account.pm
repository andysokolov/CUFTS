package CUFTS::CJDB4::Controller::Account;
use Moose;
use namespace::autoclean;

use CUFTS::CJDB::Authentication::LDAP;

use String::Util qw(hascontent trim);

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

CUFTS::CJDB4::Controller::Account - Catalyst Controller

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
    $c->account(undef);

	$c->redirect( $c->uri_for_site( $c->controller('Root')->action_for('site_index') ) );
}


sub login :Chained('base') :PathPart('login') :Args(0) {
    my ( $self, $c ) = @_;

    if ( $c->req->params->{login} ) {

    	my $key      = trim( $c->req->params->{key} );
    	my $password = trim( $c->req->params->{password} );
    	my $site     = $c->site;

        if ( hascontent($key) ) {

            my $account;

            if ( hascontent($site->cjdb_authentication_module) ) {
                # Get our internal record, then check external system for password

                $account = $site->cjdb_accounts->retrieve({ key => $key });
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
                $account = $site->cjdb_accounts->retrieve({ key => $key, password => $crypted_pass });
            }

            if ( defined($account) ) {

                if ( $account->active ) {
                    $c->account($account);
                    $c->session->{ $site->id }->{current_account_id} = $account->id;
					$c->redirect( $c->uri_for_site( $c->controller('Root')->action_for('site_index') ) );
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



=encoding utf8

=head1 AUTHOR

Todd Holbrook

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
