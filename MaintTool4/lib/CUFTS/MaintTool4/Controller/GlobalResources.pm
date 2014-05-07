package CUFTS::MaintTool4::Controller::GlobalResources;

use Moose;
use namespace::autoclean;

use String::Util qw( hascontent trim );
use CUFTS::ResourcesLoader;
use CUFTS::JQ::Client;

use Data::FormValidator::Constraints qw(:closures);

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

CUFTS::MaintTool4::Controller::GlobalResources - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub base :Chained('/loggedin') :PathPart('global_resources') :CaptureArgs(0) {
    my ( $self, $c ) = @_;

    if ( !$c->user->edit_global && !$c->user->administrator ) {
        # TODO: Change this to a flash and forward to an unauthorized action screen.
        die( $c->loc('User not authorized for global editting') );
        $c->detach;
    }
}

sub load_global_resource :Chained('base') :PathPart('') CaptureArgs(1) {
    my ( $self, $c, $resource_id ) = @_;

    $c->stash->{global_resource} = $c->model('CUFTS::GlobalResources')->find({ id => $resource_id });
    if ( !defined $c->stash->{global_resource} ) {
        die( $c->loc('Unable to find global resource id: ') . $resource_id );
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
        $c->session->{global_list_show} = $c->form->valid->{show};
    }

    if ( $c->form->valid->{apply_filter} ) {
        $c->session->{global_list_filter} = $c->form->valid->{filter};
    }

    if ( $c->form->valid->{sort} ) {
        $c->session->{global_list_sort} = $c->form->valid->{sort};
    }

    my %search;

    # Filter by name or provider
    if ( $c->session->{global_list_filter} ) {
        my $filter = $c->session->{global_list_filter};
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
    if ( hascontent($c->session->{global_list_show}) && $c->session->{global_list_show} eq 'show active' ) {
        $search{active} = 'true';
    }

    my %sort_map = (
        name        => 'LOWER(name)',
        name_d      => 'LOWER(name) DESC',
        provider    => 'LOWER(provider), LOWER(name)',
        provider_d  => 'LOWER(provider) DESC, LOWER(name)',
        scanned     => 'title_list_scanned, LOWER(name)',
        scanned_d   => 'title_list_scanned DESC, LOWER(name)',
        next        => 'next_update, LOWER(name)',
        next_d      => 'next_update DESC, LOWER(name)',
    );

    my %search_options = (
        order_by  => $sort_map{$c->session->{global_list_sort} || 'name'},
        page      => int( $c->form->valid('page') || 1 ),
        rows      => 30,
        prefetch  => [ 'resource_type' ],
    );


    my $resources_rs = $c->model('CUFTS::GlobalResources')->search( \%search, \%search_options );

    # Delete the title list filter, it should be clear when we go to browse a new title list
    delete $c->session->{global_titles_filter};

    $c->stash->{page}           = $c->form->valid('page');
    $c->stash->{sort}           = $c->session->{global_list_sort} || 'name';
    $c->stash->{filter}         = $c->session->{global_list_filter};
    $c->stash->{show}           = $c->session->{global_list_show} || 'show all';
    $c->stash->{resources_rs}   = $resources_rs;
    $c->stash->{template}       = 'global_resources/list.tt';
}


sub view :Chained('load_global_resource') :PathPart('view') :Args(0) {
    my ( $self, $c ) = @_;

    my $resource = $c->stash->{global_resource};

    # Find sites with this resource activated

    my @activated;
    foreach my $local_resource ( $resource->local_resources->search({ active => 't' }) ) {
        my $name = $local_resource->site->name;
        next if !hascontent($name);
        push @activated, [ $name, $local_resource->auto_activate, $local_resource->id, $local_resource->site->email ];
    }
    @activated = sort { lc($a->[0]) cmp lc($b->[0]) } @activated;

    # Get recent jobs

    my @jobs = $resource->jobs->search( {}, { order_by => { -desc => 'id' }, rows => 10 } )->all;

    # Setup stash

    $c->stash->{gr_page}   = $c->request->params->{gr_page} || 1;
    $c->stash->{resource}  = $resource;
    $c->stash->{activated} = \@activated;
    $c->stash->{jobs}      = \@jobs;
    $c->stash->{template}  = 'global_resources/view.tt';
}



sub edit :Chained('base') :PathPart('edit') :Args(1) {
    my ( $self, $c, $resource_id ) = @_;

    my $resource;
    if ( $resource_id ne 'new' ) {
        $resource = $c->model('CUFTS::GlobalResources')->find({ id => $resource_id });
        if ( !defined $resource ) {
            die( $c->loc('Unable to find resource id: ') . $resource_id );
            $c->detach;
            return;
        }
    }


    $c->form({
        required => [ qw( name resource_type module ) ],
        optional => [
            'gr_page',
            # Standard fields
            qw( key provider active submit cancel),
            # Resource details...
            qw( resource_identifier database_url title_list_url update_months auth_name auth_passwd url_base notes_for_local ),
        ],
        defaults => { active => 'false' },
        filters  => ['trim'],
        field_filters => { update_months => 'integer' },
        missing_optional_valid => 1,
    });

    if ( hascontent($c->form->valid->{submit}) ) {

        $c->stash->{form_submitted} = 1;
        $c->stash->{params} = $c->request->params;  # Put params in stash so they can be re-displayed in case of error

        unless ($c->form->has_missing || $c->form->has_invalid || $c->form->has_unknown) {

            eval {
                $c->model('CUFTS')->txn_do( sub {
                    if (defined($resource)) {
                        $resource->update_from_fv($c->form);
                    } else {
                        $resource = $c->model('CUFTS::GlobalResources')->create_from_fv($c->form);
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
                # return $c->redirect( $c->uri_for( $c->controller->action_for('list') ) );
            }
        }
    }

    $c->stash->{gr_page}           = $c->form->valid->{gr_page} || 1;
    $c->stash->{resource}          = $resource;
    $c->stash->{module_list}       = [ CUFTS::ResourcesLoader->list_modules() ];
    $c->stash->{resource_types}    = [ $c->model('CUFTS::ResourceTypes')->all() ];
    $c->stash->{template}          = 'global_resources/edit.tt';
}

##
## Mark resource for deleting, then return to global list
##

sub delete :Chained('load_global_resource') :PathPart('delete') :Args(0) {
    my ( $self, $c ) = @_;

    my $resource = $c->stash->{global_resource};

    if ( $c->req->params->{do_delete} ) {
        my $job = $c->job_queue->add_job({
            info               => 'Delete global resource (' . $resource->id . '): ' . $resource->name,
            type               => 'global resources',
            class              => 'global resource delete',
            global_resource_id => $resource->id,
        });

        push @{$c->flash->{results}}, $c->loc('Created deletion job for global resource: ') . $job->id;

        return $c->redirect( $c->uri_for( $c->controller('GlobalResources')->action_for('list'), { page => $c->req->params->{gr_page} } ) );
    }

    $c->stash->{gr_page}  = $c->req->params->{gr_page} || 1;
    $c->stash->{template} = 'global_resources/delete.tt';
}


##
## Title list handling
##

sub titles_list :Chained('load_global_resource') :PathPart('titles') :Args(0) {
    my ( $self, $c) = @_;

    my $resource = $c->stash->{global_resource};

    $resource->do_module('has_title_list') or
        die( $c->loc('This resource does not support title lists.') );

    my $titles_rs = $resource->do_module('global_rs', $c->model('CUFTS')->schema);
    defined $titles_rs or
        die( $c->loc('Attempt to view title list for resource type without a global_rs.') );

    ##
    ## Validate form
    ##

    $c->form({
            optional => [ qw( filter apply_filter page gr_page ) ],
            filters  => ['trim'],
            defaults => { page => 1 },
    });

    ##
    ## Build search filter
    ##

    my %search = ( resource => $resource->id );

    my $filter = $c->form->{valid}->{filter};
    if ( hascontent($filter) ) {
        $filter =~ s/([%_])/\\$1/g; # Escape some SQL special characters so they can be searched for
        $filter =~ s#\\#\\\\\\\\#;
        $search{-nest} = $resource->do_module('filter_on', $filter);
    }

    ##
    ## Setup search options - paging, sort, rows, etc.
    ##

    my %search_options = (
        order_by => 'lower(title)',
        page     => $c->form->valid('page'),
        rows     => 25,
    );

    $titles_rs = $titles_rs->search( \%search, \%search_options );

    $c->stash->{page}      = $c->form->valid->{page};
    $c->stash->{gr_page}   = $c->form->valid->{gr_page};
    $c->stash->{resource}  = $resource;
    $c->stash->{titles_rs} = $titles_rs;
    $c->stash->{filter}    = $c->form->{valid}->{filter};
    $c->stash->{template}  = 'global_resources/titles/list.tt';
}


sub title_edit :Chained('load_global_resource') :PathPart('title') :Args(1) {
    my ( $self, $c, $title_id ) = @_;

    my $resource    = $c->stash->{global_resource};
    my $resource_id = $resource->id;

    $resource->do_module('has_title_list') or
        die( $c->loc('This resource does not support title lists.') );

    my $titles_rs = $resource->do_module('global_rs', $c->model('CUFTS')->schema);
    defined $titles_rs or
        die( $c->loc('Attempt to view title list for resource type without a global_rs.') );

    my $title;
    if ( $title_id ne 'new' && int($title_id) ) {
        $title = $titles_rs->find( int($title_id) );
        defined $title or
            die( $c->loc('Unable to find title id: ') . $title_id );
    }

    my $fields = [ @{$resource->do_module('title_list_fields')} ];
    if ( !grep { $_ eq 'journal_auth' } @$fields ) {
        push @$fields, 'journal_auth'; ## Should probably not be hardcoded here.
    }

    my %validate = (
        optional => [ qw( page filter submit gr_page gt_page ) ],
        required => [ 'title' ],
        filters  => ['trim'],
        missing_optional_valid => 1,
    );

    # TODO: Can we pull validation from the model/resource module. Might be useful.
    push @{$validate{optional}}, grep { $_ ne 'title' } @$fields;
    $validate{constraints}      = $resource->do_module('validate_hash');
    $c->stash->{field_messages} = $resource->do_module('validate_english_hash');

    $c->form(\%validate);

    if ( hascontent($c->form->valid->{submit}) ) {

        $c->stash->{form_submitted} = 1;
        $c->stash->{params} = $c->request->params;  # Put params in stash so they can be re-displayed in case of error

        unless ($c->form->has_missing || $c->form->has_invalid || $c->form->has_unknown) {

            eval {
                if ( defined $title ) {
                    $title->update_from_fv($c->form);
                }
                else {
                    $title = $titles_rs->create_from_fv($c->form, { resource => $resource_id });
                    # TODO: BUGFIX: Some kind of trigger to add auto-activate titles to local resources
                }
            };
            if ($@) {
                $c->stash->{form_errors} = [ $c->loc('Transaction failed: ') . $@ ];
            }
            else {
                push @{$c->stash->{results}}, $c->loc('Title data updated.');
                delete $c->stash->{params};
            }
        }
    }

    $c->stash->{gr_page}  = $c->form->valid->{gr_page};
    $c->stash->{gt_page}  = $c->form->valid->{gt_page};
    $c->stash->{page}     = $c->form->valid->{page};
    $c->stash->{filter}   = $c->form->valid->{filter};
    $c->stash->{fields}   = $fields;
    $c->stash->{title}    = $title;
    $c->stash->{resource} = $resource;
    $c->stash->{template} = 'global_resources/titles/edit.tt';
}


sub bulk :Chained('load_global_resource') :PathPart('bulk') :Args(0) {
    my ( $self, $c ) = @_;

    my $resource    = $c->stash->{global_resource};
    my $resource_id = $resource->id;

    if ( $c->req->params->{upload} ) {

        $c->form({ required => ['file', 'upload'], optional => ['gr_page'] });
        $c->stash->{form_submitted} = 1;

        unless ($c->form->has_missing || $c->form->has_invalid || $c->form->has_unknown) {

            if ( my $upload = $c->req->upload('file') ) {

                # Grab the title list upload and copy it to the right place

                my $upload_dir = $CUFTS::Config::CUFTS_TITLE_LIST_UPLOAD_DIR;

                my ($sec, $min, $hour, $mday, $mon, $year, $wday) = localtime(time);
                $mon += 1;
                $year += 1900;

                my $filename = $upload_dir . "/titles_${resource_id}_${year}-${mon}-${mday}_${hour}-${min}-${sec}";

                $upload->copy_to($filename) or
                    die("Unable to copy title list file '$filename': $!");

                # Create a new job to load this title

                my $job = $c->job_queue->add_job({
                    info               => 'Global title list load  (' . $resource_id . '): ' . $resource->name,
                    class              => 'global title list load',
                    type               => 'global resource',
                    global_resource_id => $resource_id,
                    data               => { file => $filename },
                });

                push @{$c->stash->{results}}, $c->loc( 'Created load job for title list: ') . $job->id;
            }
        }
    }

    $c->stash->{gr_page}  = $c->req->params->{gr_page};
    $c->stash->{resource} = $resource;
    $c->stash->{template} = 'global_resources/bulk.tt';
}


=head1 AUTHOR

tholbroo

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
