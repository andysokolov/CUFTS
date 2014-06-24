package CUFTS::MaintTool4::Controller::LocalResources;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

use String::Util qw(hascontent trim);

=head1 NAME

CUFTS::MaintTool4::Controller::LocalResources - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


sub base :Chained('/loggedin') :PathPart('local_resources') :CaptureArgs(0) {
    my ( $self, $c ) = @_;

    if ( !$c->user->edit_global && !$c->user->administrator ) {
        # TODO: Change this to a flash and forward to an unauthorized action screen.
        die( $c->loc('User not authorized for global editting') );
        $c->detach;
    }
}

sub load_resources :Chained('base') :PathPart('') :CaptureArgs(2) {
    my ( $self, $c, $type, $resource_id ) = @_;

    $c->stash->{load_resource_type} = $type;
    $c->stash->{resource_id}        = $resource_id;

    return if $resource_id eq 'new';

    if ( $type eq 'local' ) {

        $c->stash->{local_resource} = $c->model('CUFTS::LocalResources')->search({ site => $c->site->id, id => $resource_id })->first;
        if ( !$c->stash->{local_resource} ) {
            die( $c->loc('Unable to find local resource id: ') . $resource_id );
            $c->detach;
            return;
        }
        $c->stash->{global_resource} = $c->stash->{local_resource}->global_resource;

    }
    else {

        $c->stash->{global_resource} = $c->model('CUFTS::GlobalResources')->find({ id => $resource_id });
        if ( !$c->stash->{global_resource} ) {
            die( $c->loc('Unable to find global resource id: ') . $resource_id );
            $c->detach;
            return;
        }
        $c->stash->{local_resource} = $c->model('CUFTS::LocalResources')->search({ site => $c->site->id, resource => $resource_id })->first;

    }
}



sub list :Chained('base') :PathPart('') :Args(0) {
    my ( $self, $c ) = @_;

    $c->form({
            optional => [ qw( show_active filter apply_filter sort page ) ],
            filters  => ['trim'],
    });

    if ( defined($c->form->valid->{show_active}) ) {
        $c->session->{local_list_show} = $c->form->valid->{show_active};
    }

    if ( $c->form->valid->{apply_filter} ) {
        $c->session->{local_list_filter} = $c->form->valid->{filter};
    }

    if ( $c->form->valid->{sort} ) {
        $c->session->{local_list_sort} = $c->form->valid->{sort};
    }

    my %search;

    # Filter by name or provider
    if ( $c->session->{local_list_filter} ) {
        my $filter = $c->session->{local_list_filter};
        $filter =~ s/([%_])/\\$1/g;
        $filter =~ s#\\#\\\\\\\\#;

        $search{'-or'} = {
             name => { ilike => "\%$filter\%" },
             provider => { ilike => "\%$filter\%" },
        };
    }

    my $resources_rs = $c->model('CUFTS::ResourcesList')->search_site( $c->site->id );

    # Filter on only active resources
    if ( $c->session->{local_list_show} eq 'active' ) {
        $search{active} = 'true';
    }
    elsif ( $c->session->{local_list_show} eq 'inactive' ) {
        $search{active} = [ undef, 'false' ];
    }

    my %sort_map = (
        name        => 'LOWER(name)',
        name_d      => 'LOWER(name) DESC',
        provider    => 'LOWER(provider), LOWER(name)',
        provider_d  => 'LOWER(provider) DESC, LOWER(name)',
        rank        => 'rank, LOWER(name)',
        rank_d      => 'rank DESC, LOWER(name)',
        scanned     => 'title_list_scanned, LOWER(name)',
        scanned_d   => 'title_list_scanned DESC, LOWER(name)',
    );

    my %search_options = (
        order_by => $sort_map{$c->session->{local_list_sort} || 'name'},
        page     => int( $c->form->valid('page') || 1 ),
        rows     => 30,
    );

    $resources_rs = $resources_rs->search( \%search, \%search_options );

    # Delete the title list filter, it should be clear when we go to browse a new title list
    delete $c->session->{local_titles_filter};

    $c->stash->{page}         = $c->form->valid('page');
    $c->stash->{sort}         = $c->session->{local_list_sort} || 'name';
    $c->stash->{filter}       = $c->session->{local_list_filter};
    $c->stash->{show_active}  = $c->session->{local_list_show};
    $c->stash->{resources_rs} = $resources_rs;
    $c->stash->{template}     = 'local_resources/list.tt';
}

sub view :Chained('load_resources') :PathPart('view') :Args(0) {
    my ( $self, $c ) = @_;

    # Get recent jobs

    my @jobs = $c->stash->{local_resource}->jobs->search( {}, { order_by => { -desc => 'id' }, rows => 10 } )->all;

    $c->stash->{jobs}      = \@jobs;
    $c->stash->{lr_page}   = $c->request->params->{lr_page};
    $c->stash->{template}  = 'local_resources/view.tt';
}

sub edit :Chained('load_resources') :PathPart('edit') :Args(0) {
    my ($self, $c) = @_;

    my $local_resource  = $c->stash->{local_resource};
    my $global_resource = $c->stash->{global_resource};

    my $form_validate = {
        required => [],
        optional => [ qw(
            lr_page submit
            provider proxy dedupe rank auto_activate active
            resource_identifier database_url title_list_url update_months auth_name auth_passwd url_base notes_for_local cjdb_note proxy_suffix erm_main
        ) ],
        defaults => {
            active              => 'false',
            proxy               => 'false',
            dedupe              => 'false',
            auto_activate       => 'false',
        },
        filters  => ['trim'],
        field_filters => { update_months => 'integer' },
        missing_optional_valid => 1,
    };
    if ( !$global_resource ) {
        push @{$form_validate->{required}}, qw( name resource_type module );
    }


    if ( hascontent($c->request->params->{submit}) ) {

        $c->form($form_validate);
        my $params = $c->request->params;  # Put params in stash so they can be re-displayed in case of error

        unless ($c->form->has_missing || $c->form->has_invalid || $c->form->has_unknown) {

            eval {
                $c->model('CUFTS')->txn_do( sub {
                    if ( defined $local_resource ) {
                        $local_resource->update_from_fv($c->form);
                    }
                    else {
                        $local_resource = $c->model('CUFTS::LocalResources')->create_from_fv($c->form, { site => $c->site->id, resource => defined($global_resource) ? $global_resource->id : undef });
                        $c->stash->{local_resource} = $local_resource;
                        push @{$c->flash->{results}}, $c->loc('Created new local resource.');
                    }

                    if ( defined $global_resource && $local_resource->auto_activate ) {
                        $local_resource->do_module('activate_local_titles', $c->model('CUFTS')->schema, $local_resource);
                    }
                });

            };
            if ($@) {
                push @{$c->stash->{errors}}, $c->loc('Transaction failed: ') . $@;
                warn( $c->loc('Transaction failed: ') . $@ );
            }
            else {
                push @{$c->stash->{results}}, $c->loc('Resource data updated.');
                delete $c->stash->{params}; # Use the updated record instead of any saved parameters
            }
        }
    }

    if ( $c->stash->{resource_id} eq 'new' && $local_resource ) {
        return $c->redirect( $c->uri_for( $c->controller('LocalResources')->action_for('edit'), ['local', $local_resource->id ], { lr_page => $c->req->params->{lr_page} } ) );
    }

    $c->stash->{lr_page}           = $c->form->valid->{lr_page};
    $c->stash->{module_list}       = [ CUFTS::ResourcesLoader->list_modules() ];
    $c->stash->{resource_types}    = [ $c->model('CUFTS::ResourceTypes')->all() ];
    $c->stash->{template}          = $c->stash->{global_resource} ? 'local_resources/edit_global.tt' : 'local_resources/edit_local.tt';
}


##
## Mark resource for deleting, then return to local list
##

sub delete :Chained('load_resources') :PathPart('delete') :Args(0) {
    my ( $self, $c ) = @_;

    my $resource = $c->stash->{local_resource};

    if ( $c->req->params->{do_delete} ) {
        my $job = $c->job_queue->add_job({
            info               => 'Delete local resource (' . $resource->id . '): ' . ( $resource->name || $resource->resource->name ),
            type               => 'local resources',
            class              => 'local resource delete',
            local_resource_id  => $resource->id,
        });

        push @{$c->flash->{results}}, $c->loc('Created deletion job for local resource: ') . $job->id;

        return $c->redirect( $c->uri_for( $c->controller('LocalResources')->action_for('list'), { page => $c->req->params->{lr_page} } ) );
    }

    $c->stash->{lr_page}  = $c->req->params->{lr_page};
    $c->stash->{template} = 'local_resources/delete.tt';
}


=head1 AUTHOR

tholbroo

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
