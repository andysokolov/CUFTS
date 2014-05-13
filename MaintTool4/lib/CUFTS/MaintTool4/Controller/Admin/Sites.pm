package CUFTS::MaintTool4::Controller::Admin::Sites;
use Moose;
use namespace::autoclean;

use String::Util qw(trim hascontent);

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

CUFTS::MaintTool4::Controller::Admin::Sites - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


sub base :Chained('/loggedin') :PathPart('site') :CaptureArgs(0) {
    my ( $self, $c ) = @_;

    if ( !$c->user->administrator ) {
        die( $c->loc('Administrator access required') );
    }
}

sub load_site :Chained('base') :PathPart('') CaptureArgs(1) {
    my ( $self, $c, $site_id ) = @_;

    if ( $site_id ne 'new' ) {
        $c->stash->{site} = $c->model('CUFTS::Sites')->find({ id => $site_id });
        if ( !defined $c->stash->{site} ) {
            die( $c->loc('Unable to find site id: ') . $site_id );
            $c->detach;
        }
    }
}


sub list :Chained('base') :PathPart('') :Args(0) {
    my ( $self, $c ) = @_;

    $c->form({
            optional => [ qw( filter apply_filter page ) ],
            filters  => ['trim'],
    });

    if ( $c->form->valid->{apply_filter} ) {
        $c->session->{admin_sites_filter} = $c->form->valid->{filter};
    }

    my %search;

    # Filter by name or provider
    if ( my $filter =  $c->session->{admin_sites_filter} ) {
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

    my $sites_rs = $c->model('CUFTS::Sites')->search( \%search, \%search_options );

    $c->stash->{page}           = $c->form->valid('page');
    $c->stash->{filter}         = $c->session->{admin_sites_filter};
    $c->stash->{sites_rs}    = $sites_rs;
    $c->stash->{template}       = 'admin/sites/list.tt';
}

sub edit :Chained('load_site') :PathPart('edit') :Args(0) {
    my ( $self, $c ) = @_;

    my $site = $c->stash->{site};

    $c->form({
        required => [ qw( key name )],
        optional => [ qw( email erm_notification_email proxy_prefix proxy_prefix_alternate proxy_wam active submit admin_site_page ) ],
        filters  => [ 'trim' ],
        defaults => {
            active        => 'false',
        },
        missing_optional_valid => 1,
    });

    if ( hascontent($c->form->valid->{submit}) ) {

        $c->stash->{form_submitted} = 1;
        $c->stash->{params} = $c->request->params;

        unless ( $c->form->has_missing || $c->form->has_invalid || $c->form->has_unknown ) {
            eval {
                if ( defined $site ) {
                    $site->update_from_fv($c->form);
                }
                else {
                    $site = $c->model('CUFTS::Sites')->create_from_fv($c->form);
                }
            };
            if ($@) {
                push @{$c->stash->{errors}}, $@;
            }
            else {
                push @{$c->stash->{results}}, $c->loc('Site data updated.');
                delete $c->stash->{params}; # Use the updated record instead of any saved parameters
            }

        }
    }

    $c->stash->{admin_site_page} = $c->form->valid->{admin_site_page};
    $c->stash->{site}            = $site;
    $c->stash->{template}        = 'admin/sites/edit.tt';
}


sub delete :Chained('load_site') :PathPart('delete') :Args(0) {
    my ( $self, $c ) = @_;

    my $site = $c->stash->{site};

    if ( $c->req->params->{do_delete} ) {
        # Create a new job to load this title

        my $job = $c->job_queue->add_job({
            info               => 'Delete site (' . $site->id . '): ' . $site->name,
            class              => 'site delete',
            type               => 'site',
            data               => { site_id => $site->id },
        });

        push @{$c->flash->{results}}, $c->loc( 'Created delete job for site: ') . $job->id;
        return $c->redirect( $c->uri_for( $c->controller('Admin::Sites')->action_for('list'), { page => $c->req->params->{admin_site_page} } ) );
    }

    $c->stash->{admin_site_page} = $c->form->valid->{admin_site_page};
    $c->stash->{site}            = $site;
    $c->stash->{template}        = 'admin/sites/delete.tt';
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
