package CUFTS::MaintTool4::Controller::Jobs;
use Moose;
use namespace::autoclean;

use CUFTS::JQ::Client;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

CUFTS::MaintTool4::Controller::Jobs - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub base :Chained('/loggedin') :PathPart('jobs') :CaptureArgs(0) {
    my ( $self, $c ) = @_;
}

sub load_job :Chained('base') :PathPart('') CaptureArgs(1) {
    my ( $self, $c, $job_id ) = @_;

    $c->stash->{job} = $c->job_queue->get_job($job_id);
    if ( !defined $c->stash->{job} ) {
        die( $c->loc('Unable to load job id: ') . $job_id );
        $c->detach;
    }

}

sub list :Chained('base') :PathPart('') :Args(0) {
    my ( $self, $c ) = @_;

    $c->form({
            optional => [ qw( show filter apply_filter sort page ) ],
            filters  => ['trim'],
    });

    if ( $c->form->valid->{show} ) {
        $c->session->{job_list_show} = $c->form->valid->{show};
    }

    if ( $c->form->valid->{apply_filter} ) {
        $c->session->{job_list_filter} = $c->form->valid->{filter};
    }

    if ( $c->form->valid->{sort} ) {
        $c->session->{job_list_sort} = $c->form->valid->{sort};
    }

    my %search;

    # Filter by name or provider
    if ( $c->session->{job_list_filter} ) {
        my $filter = $c->session->{job_list_filter};
        $filter =~ s/([%_])/\\$1/g;
        $filter =~ s#\\#\\\\\\\\#;

        $search{'-or'} = {
             name => { ilike => "\%$filter\%" },
             provider => { ilike => "\%$filter\%" },
        };

        if ( $filter =~ /^\d+$/ ) {
            $search{'-or'}->{'me.id'} = int($filter);
        }
    }

    # Filter on only active resources
    # if ( hascontent($c->session->{job_list_show}) && $c->session->{job_list_show} eq 'show active' ) {
    #     $search{active} = 'true';
    # }

    my %sort_map = (
       runnable    => [ { -desc => 'run_after' }, { -desc => 'priority' }, { -desc => 'id' } ],
    );

    my %search_options = (
        order_by  => $sort_map{ $c->session->{job_list_sort} || 'runnable' },
        page      => int( $c->form->valid('page') || 1 ),
        rows      => 30,
    );

    my ( $jobs, $pager ) = $c->job_queue->list_jobs( {}, \%search_options );

    $c->stash->{page}     = $c->form->valid('page') || 1;
    $c->stash->{sort}     = $c->session->{job_list_sort} || 'runnable';
    $c->stash->{filter}   = $c->session->{job_list_filter};
    $c->stash->{show}     = $c->session->{job_list_show} || 'show all';
    $c->stash->{jobs}     = $jobs;
    $c->stash->{pager}    = $pager;
    $c->stash->{template} = 'jobs/list.tt';
}

sub view :Chained('load_job') :PathPart('view') :Args(0) {
    my ( $self, $c ) = @_;

    my ( $logs, $pager ) = $c->stash->{job}->get_logs({}, { page => $c->request->params->{page} } );

    $c->stash->{logs}        = $logs;
    $c->stash->{pager}       = $pager;
    $c->stash->{template}    = 'jobs/view.tt';
}

sub terminate :Chained('load_job') :PathPart('terminate') :Args(0) {
    my ( $self, $c ) = @_;

    $c->stash->{job}->terminate();

    $c->redirect( $c->uri_for( $c->controller->action_for('list'), { page => $c->request->params->{job_page} } ) );
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
