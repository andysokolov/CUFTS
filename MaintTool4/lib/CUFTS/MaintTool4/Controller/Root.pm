package CUFTS::MaintTool4::Controller::Root;
use Moose;
use namespace::autoclean;

use String::Util qw(hascontent trim);

BEGIN { extends 'Catalyst::Controller' }

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config(namespace => '');

=head1 NAME

CUFTS::MaintTool4::Controller::Root - Root Controller for CUFTS::MaintTool4

=head1 DESCRIPTION

[enter your description here]

=head1 METHODS

=cut

sub base : Chained('/') PathPart('') CaptureArgs(0) {}

sub loggedin :Chained('base') :PathPart('') :CaptureArgs(0) {
    my ( $self, $c ) = @_;

    if ( !$c->user ) {
        return $c->redirect( $c->uri_for($c->controller('Root')->action_for('login')) );
    }

    if ( my $site_id = $c->session->{current_site_id} ) {
		$c->site( $c->model('CUFTS::Sites')->find({ id => $site_id }) );
    }

    $self->_setup_menu($c);

    $c->stash->{breadcrumbs} = [ [ $c->uri_for( $c->controller('Root')->action_for('index') ), $c->loc('Home') ] ];
}


sub access_denied :Chained('base') :PathPart('access_denied') :Args(0) {
    my ( $self, $c ) = @_;

    $c->stash->{template} = 'access_denied.tt';
}


=head2 login

The login action, forwards to the user home page or a detailed login page if it fails

=cut

sub login :Chained('/') :PathPart('login') :Args(0) {
    my ( $self, $c ) = @_;

    if ( $c->req->params->{submit} ) {

        $c->form({
            required => [ 'login_key', 'login_password' ],
            optional => [ 'submit' ],
            filters  => [ 'trim' ],
        });

        $c->stash->{form_submitted} = 1;
        $c->stash->{params} = { login_key => $c->req->params->{login_key} };

        my $pw  = $c->form->valid('login_password');
        my $key = $c->form->valid('login_key');
        my $user = $c->find_user({ key => $key });

        if ( !defined($user) ) {
            $c->stash->{form_errors} = [ $c->loc('User not found.') ];
        }
        elsif ( !$user->active ) {
            $c->stash->{form_errors} = [ $c->loc('User is not marked as active.') ];
        }
        elsif ( !$user->check_password($pw) ) {
            $c->stash->{form_errors} = [ $c->loc('Incorrect password.') ];
        }
        else {

            $c->set_authenticated($user);
            $user->update_last_login();

            my @sites = $user->sites->all;
            if ( scalar @sites == 1 ) {
                $c->session->{current_site_id} = $sites[0]->id;
            }

            return $c->redirect( $c->uri_for( $c->controller('Root')->action_for('index') ) );
        }

    }

    $c->stash->{template} = 'login.tt'
}


sub logout :Chained('/loggedin') :PathPart('logout') :Args(0) {
    my ( $self, $c ) = @_;
    $c->logout();
    return $c->redirect( $c->uri_for( $c->controller('Root')->action_for('index') ) );
}


sub index :Chained('/loggedin') :PathPart('') :Args(0) {
    my ( $self, $c ) = @_;

    my $job_search = { account_id => $c->user->id };
    $job_search->{site_id} = $c->site->id if defined $c->site;

    my ( $jobs, $pager ) = $c->job_queue->list_jobs(
        {
            -or => $job_search
        },
        {
            rows => 10,
        }
    );

    $c->stash->{jobs}     = $jobs;
    $c->stash->{pager}    = $pager;
    $c->stash->{template} = 'index.tt'
}

=head2 default

Standard 404 error page

=cut

# sub default :Path {
#     my ( $self, $c ) = @_;
#     $c->response->body( 'Page not found' );
#     $c->response->status(404);
# }

=head2 end

Attempt to render a view, if needed.

=cut

sub end : ActionClass('RenderView') {
    my ( $self, $c ) = @_;
    if ( !hascontent($c->stash->{results}) && hascontent($c->flash->{results}) ) {
        $c->stash->{results} = $c->flash->{results};
    }

    if ( !$c->response->content_type ) {
        $c->response->content_type('text/html; charset=iso-8859-1');
    }

}

sub _setup_menu {
    my ( $self, $c ) = @_;

    my @menu;
    my $user = $c->user;
    my $site = $c->site;

    if ( defined($user) ) {
        push @menu, [ $c->loc('Home'),   $c->uri_for( $c->controller('Root')->action_for('index') ) ];

        if ( $user->administrator || length(user->sites) > 1 ) {
            push @menu, [ $c->loc('Change Site'), $c->uri_for( $c->controller('Site')->action_for('change') ) ];
        }

        if ( $c->site ) {
            push @menu, [ $c->loc('Local Resources'), $c->uri_for( $c->controller('LocalResources')->action_for('list'), { page => 1, filter => '', apply_filter => 1, show_active => 'all' } ) ]
        }

        if ( $user->administrator || $user->edit_global ) {
            push @menu, [ $c->loc('Global Resources'), $c->uri_for( $c->controller('GlobalResources')->action_for('list'), { page => 1, filter => '', apply_filter => 1 } ) ];
        }

        if ( $c->site ) {
            push @menu, [ $c->loc('Site Settings'), [
                [ $c->loc('General'),           $c->uri_for( $c->controller('Site')->action_for('edit') ) ],
                [ $c->loc('CJDB Templates'),    $c->uri_for( $c->controller('Site::Templates')->action_for('menu'), ['cjdb4'] ) ],
                [ $c->loc('CJDB Settings'),     $c->uri_for( $c->controller('Site::CJDB')->action_for('settings') ) ],
                [ $c->loc('CJDB Data'),         $c->uri_for( $c->controller('Site::CJDB')->action_for('data') ) ],
                [ $c->loc('CRDB Templates'),    $c->uri_for( $c->controller('Site::Templates')->action_for('menu'), ['crdb4'] ) ],
                [ $c->loc('C*DB Accounts'),     $c->uri_for( $c->controller('Site::CJDB')->action_for('accounts') ) ],
                [ $c->loc('Google Scholar'),    $c->uri_for( $c->controller('Site')->action_for('google_scholar') ) ],
            ] ];
        }

        push @menu, [ $c->loc('Jobs'), $c->uri_for( $c->controller('Jobs')->action_for('list') ) ];

        push @menu, [ $c->loc('Account Settings'), $c->uri_for( $c->controller('Account')->action_for('edit') ) ];

        if ( $user->administrator ) {
            push @menu, [ $c->loc('Administration'), [
                [ $c->loc('Accounts'), $c->uri_for( $c->controller('Admin::Accounts')->action_for('list') ) ],
                [ $c->loc('Sites'),    $c->uri_for( $c->controller('Admin::Sites')->action_for('list') ) ],
            ] ];
        }

        push @menu, [ $c->loc('Logout'), $c->uri_for( $c->controller('Root')->action_for('logout') ) ];
    }

    $c->stash->{menu} = \@menu;
}




=head1 AUTHOR

tholbroo

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
