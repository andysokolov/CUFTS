package CUFTS::MaintTool4::Controller::LocalResources::Titles;
use Moose;
use namespace::autoclean;

use String::Util    qw( trim hascontent );
use List::MoreUtils qw( uniq );
use CUFTS::Config;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

CUFTS::MaintTool4::Controller::LocalResources::Titles - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub base :Chained('../base') :PathPart('titles') :CaptureArgs(0) {}

sub load_resources :Chained('../load_resources') :PathPart('titles') :CaptureArgs(0) {
    my ( $self, $c ) = @_;

    my $local_resource  = $c->stash->{local_resource};
    my $global_resource = $c->stash->{global_resource};

    if ( defined $global_resource && !$global_resource->do_module('has_title_list') ) {
        die( $c->loc('This resource does not support title lists.') );
    }

    if ( defined $local_resource ) {
        $c->stash->{local_titles_rs} = $local_resource->do_module('local_rs', $c->model('CUFTS')->schema );
        die( $c->loc('Attempt to view title list for resource type without a local_rs.') ) if !defined $c->stash->{local_titles_rs};
    }

    if ( defined $global_resource ) {
        $c->stash->{global_titles_rs} = $global_resource->do_module('global_rs', $c->model('CUFTS')->schema );
        die( $c->loc('Attempt to view title list for resource type without a global_rs.') ) if !defined $c->stash->{global_titles_rs};
    }

}

=head2 list_global

Lists titles in a global resource with local overlayed data

=cut

sub list_global :Chained('load_resources') :PathPart('list/global') :Args(0) {
    my ($self, $c) = @_;

    my $global_resource     = $c->stash->{global_resource};
    my $local_resource      = $c->stash->{local_resource};
    my $local_rs            = $c->stash->{local_titles_rs};
    my $global_rs           = $c->stash->{global_titles_rs};
    my $ltg_field           = $global_resource->do_module('local_to_global_field'); # Local to global linking field

    ##
    ## Validate form and set control session variables (filter, show active, etc.)
    ##

    $c->form({
        optional        => [ qw( show_active page filter lr_page apply_filter apply_changes activate_all deactivate_all edit ) ],
        optional_regexp => qr/^(new|orig|hide)_.+/,
        filters         => ['trim'],
        defaults        => { filter => '', show_active => 'all', page => 1 },
    });

    if ( defined $c->form->valid->{show_active} ) {
        $c->session->{local_title_list_show} = $c->form->valid->{show_active}; # Force boolean
    }

    my %search = ( 'me.resource' => $global_resource->id );  # 'me' is needed in case we join a local titles module

    ##
    ## Build search filter and set the "show_active" flag for use later.
    ##

    my $filter = $c->form->{valid}->{filter};
    my $active = $c->form->{valid}->{show_active};

    if ( $c->form->{valid}->{apply_filter} && $filter ne ($c->session->{local_titles_filter} || '') ) {
        $c->form->{valid}->{page} = 1;  # Reset page to one if filter has changed
        $c->session->{local_titles_filter}   = $filter if $filter ne ($c->session->{local_titles_filter}   || '');
        $c->session->{local_title_list_show} = $active if $active ne ($c->session->{local_title_list_show} || '');

    }
    else {
        $filter = $c->session->{local_titles_filter}   || $filter;
        $active = $c->session->{local_title_list_show} || $active;
    }

    if ( hascontent($filter) ) {
        $filter =~ s/([%_])/\\$1/g;
        $filter =~ s#\\#\\\\\\\\#;
        $search{-nest} = $global_resource->do_module( 'filter_on', $filter, 'me.' );  # TODO: Is -nest still supported?
    }

    ##
    ## Setup search options - paging, sort, rows, etc.
    ##

    my %search_options = (
        order_by => 'lower(me.title)',
        page     => $c->form->valid('page'),
        rows     => 25,
    );

    $global_rs = $global_rs->search( \%search, \%search_options );

    ##
    ## Prefetch local linked titles if we have a local resource. Also limit to active titles if the "show active" filter is on
    ##

    if ( defined $local_resource && !$local_resource->auto_activate && $active ne 'all' ) {
        if ( $active eq 'active' ) {
            $global_rs = $global_rs->search_active_local( $local_resource->id );
        }
        elsif ( $active eq 'inactive' ) {
            $global_rs = $global_rs->search_inactive_local( $local_resource->id );
        }
        else {
            die( $c->loc('Unrecognized active flag: ') . $active );
        }
    }

    ##
    ## Activate/deactivate all titles if that button was pushed. Do this here so that the generated
    ## local titles can be loaded into the map in the next step.
    ##
    if ( $c->form->valid('activate_all') ) {
        $local_resource->do_module('activate_local_titles', $c->model('CUFTS')->schema, $local_resource);
        $c->stash->{results} = [ $c->loc('All titles activated.') ];
    }
    elsif ( $c->form->valid('deactivate_all') ) {
        $local_resource->do_module('deactivate_local_titles', $c->model('CUFTS')->schema, $local_resource);
        $c->stash->{results} = [ $c->loc('All titles deactivated.') ];
    }

    ##
    ## Build a map of global titles to local titles by id that can be used for displaying override details
    ##

    my %local_titles;
    if ( defined $local_resource && defined $local_rs ) {
        $local_rs = $local_rs->search({
            resource   => $local_resource->id,
            $ltg_field => { '-in' =>  [ map { $_->id } $global_rs->all ] },
        });
        $global_rs->reset;  # We looped through to get the ids for loading matching local titles. Reset here for display.
        %local_titles = ( map { $_->get_column($ltg_field) => $_ } $local_rs->all );
    }

    ##
    ## If the "save active" button has been pushed then go through the changes and update/create local titles
    ##

    if ( $c->form->valid('apply_changes') ) {
        eval {
            $c->model('CUFTS')->schema->txn_do( sub {
                # If we don't have a local resource yet we should make one

                if ( !defined $local_resource  ) {
                    $local_resource = $c->model('CUFTS::LocalResources')->create({ site => $c->site->id, resource => $global_resource->id, active => 0 });
                }

                while ( my $title = $global_rs->next ) {
                    my $newval  = int( $c->form->valid( 'new_'  . $title->id . '_active') || 0 );
                    my $origval = int( $c->form->valid( 'orig_' . $title->id . '_active') || 0 );
                    if ( $newval != $origval ) {
                        my $local_title = $local_titles{$title->id};
                        if ( defined $local_title ) {
                            $local_title->update({ active => $newval });
                        }
                        else {
                            $local_titles{$title->id} = $local_rs->create({ resource => $local_resource->id, $ltg_field => $title->id, active => $newval });
                        }
                    }
                }
                $global_rs->reset;
            });
        };

        if ($@) {
            push @{$c->stash->{errors}}, $c->loc('Transaction failed: ') . $@;
            warn( $c->loc('Transaction failed: ') . $@ );
        }
        else {
            push @{$c->stash->{results}}, $c->loc('Title data updated.');
        }
    }

    ##
    ## Figure out which columns are in use for this data set
    ##

    # TODO: This could likely be cleaned up a bit. It's messier than the original because I've
    #       swapped things around to only need one database iteration. Somes maps + array manipulation
    #        would likely get this down to fewer lines.

    my @temp_cols = uniq( @{$global_resource->do_module('title_list_fields')}, @{$global_resource->do_module('overridable_title_list_fields')} );
    my %seen_cols;
    while ( my $title = $global_rs->next ) {
        foreach my $col (@temp_cols) {
            next if $seen_cols{$col};
            my $local_title = $local_titles{$title->id};
            $seen_cols{$col} = 1 if hascontent($title->$col) || ( defined $local_title && hascontent( $local_title->$col ) );
        }
    }
    $global_rs->reset;  # We looped through to check for used columns
    my @columns = grep { $seen_cols{$_} } @temp_cols;

    # Make sure we have id and journal_auth columns as first and last columns

    unshift(@columns, 'id') if !grep { $_ eq 'id'} @columns;
    @columns = ( (grep { $_ ne 'journal_auth' } @columns), 'journal_auth' );

    ##
    ## Set up stash variables
    ##

    $c->stash->{columns}      = \@columns;
    $c->stash->{page}         = $c->form->valid->{page};
    $c->stash->{lr_page}      = $c->form->valid->{lr_page};
    $c->stash->{show_active}  = $c->session->{local_title_list_show};
    $c->stash->{titles_rs}    = $global_rs;         # Global titles resultsource
    $c->stash->{local_titles} = \%local_titles;     # Map of local titles by global id
    $c->stash->{filter}       = $c->session->{local_titles_filter};
    $c->stash->{template}     = 'local_resources/titles/list_global.tt';
}



=head2 list_global

Lists titles in a local resource

=cut


sub list_local :Chained('load_resources') :PathPart('list/local') :Args(0) {
    my ($self, $c) = @_;

    my $local_resource = $c->stash->{local_resource};
    my $titles_rs      = $c->stash->{local_titles_rs};

    ##
    ## Validate form and set control session variables (filter, show active, etc.)
    ##

    $c->form({
        optional        => [ qw( page filter lr_page apply_filter apply ) ],
        optional_regexp => qr/^(new|orig|hide)_.+/,
        filters         => ['trim'],
        defaults        => { filter => '', page => 1 },
    });

    my %search = ( resource => $local_resource->id );

    ##
    ## Build search filter
    ##

    my $filter = $c->form->{valid}->{filter};
    if ( $c->form->{valid}->{apply_filter} && $filter ne ($c->session->{local_titles_filter} || '') ) {
        $c->form->{valid}->{page} = 1;  # Reset page to one if filter has changed
        $c->session->{local_titles_filter} = $filter;
    }
    else {
        $filter = $c->session->{local_titles_filter};
    }

    if ( hascontent($filter) ) {
        $filter =~ s/([%_])/\\$1/g;
        $filter =~ s#\\#\\\\\\\\#;
        $search{-nest} = $local_resource->do_module('filter_on', $filter);  # TODO: Is -nest still supported?
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

    ##
    ## Figure out which columns are in use for this data set
    ##

    # TODO: This could likely be cleaned up a bit. It's messier than the original because I've
    #       swapped things around to only need one database iteration. Somes maps + array manipulation
    #        would likely get this down to fewer lines.

    my @temp_cols = uniq( @{$local_resource->do_module('title_list_fields')} );
    my %seen_cols;
    while ( my $title = $titles_rs->next ) {
        foreach my $col (@temp_cols) {
            next if $seen_cols{$col};
            $seen_cols{$col} = 1 if hascontent($title->$col);
        }
    }
    $titles_rs->reset;  # We looped through to check for used columns
    my @columns = grep { $seen_cols{$_} } @temp_cols;


    # Make sure we have id and journal_auth columns if they weren't in the original list. Make sure journal_auth is the last field.

    # TODO: Do we want journal_auth hard coded here? It's probably missing from some resource modules since it was added after many were written.

    unshift(@columns, 'id') if !grep { $_ eq 'id'} @columns;
    @columns = ( (grep { $_ ne 'journal_auth' } @columns), 'journal_auth' );

    ##
    ## Set up stash variables
    ##

    $c->stash->{columns}      = \@columns;
    $c->stash->{page}         = $c->form->valid->{page};
    $c->stash->{lr_page}      = $c->form->valid->{lr_page};
    $c->stash->{titles_rs}    = $titles_rs;
    $c->stash->{filter}       = $c->form->{valid}->{filter};
    $c->stash->{template}     = 'local_resources/titles/list_local.tt';
}



=head2 edit_global_title

Edit a single local title *attached to a global title*.  See edit_local_title for editing a local only title.

=cut

sub edit_global_title :Chained('load_resources') :PathPart('edit/global') :Args(1) {
    my ( $self, $c, $title_id ) = @_;

    my $global_resource     = $c->stash->{global_resource};
    my $local_resource      = $c->stash->{local_resource};
    my $local_rs            = $c->stash->{local_titles_rs};
    my $global_rs           = $c->stash->{global_titles_rs};
    my $overridable_fields  = $global_resource->do_module('overridable_title_list_fields');
    my $ltg_field           = $global_resource->do_module('local_to_global_field');

    ##
    ## Get the requested global title
    ##

    my $global_title = $global_rs->find({ id => $title_id, resource => $global_resource->id })
        or die( $c->loc('Unable to find global title by id') );

    ##
    ## Validate the form
    ## TODO: Add in better validation so we can catch errors on the form directly rather than letting the DB edit fail
    ##

    my %validate = (
        optional               => [ qw( lr_page lt_page apply ) ],
        filters                => [ qw( trim ) ],
        missing_optional_valid => 1,
    );
    push @{$validate{optional}}, @$overridable_fields;

    $validate{constraint_methods} = $local_resource->do_module('validate_hash');
    $c->stash->{field_messages}   = $local_resource->do_module('validate_english_hash');

    $c->form(\%validate);

    ##
    ## Get a local title if one is already created. If we're saving changes we may have to
    ## create a resource and title to hold them.
    ##

    my $local_title;
    if ( defined $local_resource ) {
        $local_title = $local_rs->find({ $ltg_field => $title_id, resource => $local_resource->id });
    }

    if ( hascontent($c->form->valid->{apply}) ) {

        $c->stash->{form_submitted} = 1;
        $c->stash->{params} = $c->request->params;  # Put params in stash so they can be re-displayed in case of error

        unless ($c->form->has_missing || $c->form->has_invalid || $c->form->has_unknown) {

            eval {

                defined($local_resource) or
                    $local_resource = $c->stash->{local_resource} = CUFTS::DB::LocalResources->create({ resource => $global_resource->id, site => $c->stash->{current_site}->id, auto_activate => 0 });

                $c->model('CUFTS')->txn_do( sub {

                    if (defined($local_title)) {
                        $local_title->update_from_fv($c->form);
                    } else {
                        $local_title = $local_rs->create_from_fv($c->form, { resource => $local_resource->id, $ltg_field => $global_title->id });
                    }

                });
            };

            if ($@) {
                push @{$c->stash->{errors}}, $c->loc('Transaction failed: ') . $@;
                warn( $c->loc('Transaction failed: ') . $@ );
            }
            else {
                push @{$c->stash->{results}}, $c->loc('Title data updated.');
                delete $c->stash->{params}; # Use the updated record instead of any saved parameters
            }
        }
    }

    $c->stash->{global_title}           = $global_title;
    $c->stash->{local_title}            = $local_title;
    $c->stash->{lt_page}                = $c->form->valid->{lt_page};
    $c->stash->{lr_page}                = $c->form->valid->{lr_page};
    $c->stash->{overridable_fields}     = $overridable_fields;
    $c->stash->{template}               = 'local_resources/titles/edit_global.tt';
}


=head2 edit_local_title

Edit a single local title not attached to a global resource.

=cut

sub edit_local_title :Chained('load_resources') :PathPart('edit/local') :Args(1) {
    my ( $self, $c, $title_id ) = @_;

    my $local_resource      = $c->stash->{local_resource};
    my $local_titles_model  = $c->stash->{local_titles_model};
    my $fields              = $local_resource->do_module('title_list_fields');
    my $local_rs            = $c->stash->{local_titles_rs};

    push@$fields, 'journal_auth' if !grep { $_ eq 'journal_auth' } @$fields;

    ##
    ## Get the requested local title
    ##

    my $local_title;
    if ( $title_id ne 'new' && int($title_id) ) {
        $local_title = $local_rs->find({ id => int($title_id), resource => $local_resource->id });
    }

    ##
    ## Validate the form
    ## TODO: Add in better validation so we can catch errors on the form directly rather than letting the DB edit fail s
    ##

    my %validate = (
        required               => [ qw( title ) ],
        optional               => [ qw( lr_page lt_page apply _new ) ],
        filters                => [ qw( trim ) ],
        missing_optional_valid => 1,
    );
    push @{$validate{optional}}, grep { $_ ne 'title' } @$fields;

    $validate{constraint_methods} = $local_resource->do_module('validate_hash');
    $c->stash->{field_messages}   = $local_resource->do_module('validate_english_hash');

    $c->form(\%validate);

    if ( hascontent($c->form->valid->{apply}) ) {

        $c->stash->{form_submitted} = 1;
        $c->stash->{params} = $c->request->params;  # Put params in stash so they can be re-displayed in case of error

        unless ($c->form->has_missing || $c->form->has_invalid || $c->form->has_unknown) {

            eval {

                $c->model('CUFTS')->txn_do( sub {

                    if ( defined $local_title ) {
                        warn('(1)');
                        $local_title->update_from_fv($c->form);
                    }
                    else {
                        warn(ref $local_rs);
                        $local_title = $local_rs->create_from_fv($c->form, { resource => $local_resource->id });
                    }

                });
            };

            if ($@) {
                push @{$c->stash->{errors}}, $c->loc('Transaction failed: ') . $@;
                warn( $c->loc('Transaction failed: ') . $@ );
            }
            else {
                push @{$c->stash->{results}}, $c->loc('Title data updated.');
                delete $c->stash->{params}; # Use the updated record instead of any saved parameters
            }
        }
    }

    if ( $title_id eq 'new' && $local_title ) {
        $c->flash->{results} = $c->stash->{results}; # Move results screen to flash for redirect
        return $c->redirect( $c->uri_for( $c->controller->action_for('edit_local_title'), ['local', $local_resource->id, $local_title->id ], { lr_page => $c->form->valid->{lr_page}, lt_page => $c->form->valid->{lt_page}, } ) );
    }


    $c->stash->{local_title}        = $local_title;
    $c->stash->{local_title_id}     = $title_id;
    $c->stash->{title_fields}       = $fields;
    $c->stash->{lt_page}            = $c->form->valid->{lt_page};
    $c->stash->{lr_page}            = $c->form->valid->{lr_page};
    $c->stash->{overridable_fields} = $local_resource->do_module('overridable_title_list_fields');
    $c->stash->{template}           = 'local_resources/titles/edit_local.tt';
}


sub bulk_local :Chained('load_resources') :PathPart('bulk/local') :Args(0) {
    my ($self, $c) = @_;

    $c->form({
        optional => [ qw( file upload export format lr_page ) ],
    });

    my $local_resource = $c->stash->{local_resource};
    defined $local_resource or
        die( $c->loc('Unable to find local resource.') );

    my $resource_id = $local_resource->id;

    if ( $c->req->params->{upload} || $c->req->params->{export} ) {

        $c->stash->{form_submitted} = 1;
        unless ($c->form->has_missing || $c->form->has_invalid || $c->form->has_unknown) {

            if ( $c->form->valid('export') ) {
                $c->stash(
                    data          => $self->_build_export_data($c),
                    current_view  => 'Tab',
                );
                $c->response->header( 'Content-Disposition' => 'attachment; filename="local_titles_' . $resource_id . '_' . DateTime->now->iso8601 . '.txt"');
                return $c->detach();
            }
            elsif ( my $upload = $c->req->upload('file') ) {

                # Grab the title list upload and copy it to the right place

                my $upload_dir = $CUFTS::Config::CUFTS_TITLE_LIST_UPLOAD_DIR;

                my ($sec, $min, $hour, $mday, $mon, $year, $wday) = localtime(time);
                $mon += 1;
                $year += 1900;

                my $filename = $upload_dir . "/titles_${resource_id}_${year}-${mon}-${mday}_${hour}-${min}-${sec}";

                $upload->copy_to($filename) or
                    die("Unable to copy title list file '$filename': $!");

                my $job = $c->job_queue->add_job({
                    info              => "Local title list load  ($resource_id): " . $local_resource->name,
                    class             => 'local title list load',
                    type              => 'local resource',
                    local_resource_id => $resource_id,
                    data              => { file => $filename, },
                });
                if ( !defined $job ) {
                    die( $c->loc('Unable to create job.') );
                }

                push @{$c->stash->{results}}, $c->loc('Title list uploaded and submitted to job queue.');
            }

        }
    }

    $c->stash->{lr_page}  = $c->form->valid('lr_page');
    $c->stash->{template} ||= 'local_resources/titles/bulk_local.tt';
}



sub bulk_global :Chained('load_resources') :PathPart('bulk/global') :Args(0) {
    my ($self, $c) = @_;

    my $global_resource = $c->stash->{global_resource};
    my $local_resource  = $c->stash->{local_resource};

    $c->form({
        optional => [ qw( file match upload export format type deactivate lr_page ) ],
    });

    if ( $c->req->params->{upload} || $c->req->params->{export} ) {

        $c->stash->{form_submitted} = 1;

        unless ($c->form->has_missing || $c->form->has_invalid || $c->form->has_unknown) {

            my $resource_id = $local_resource->id;

            if ( $c->form->valid('export') ) {
                $c->stash(
                    data         => $self->_build_export_data($c),
                    current_view => 'Tab'
                );
                $c->response->header( 'Content-Disposition' => 'attachment; filename="local_titles_' . $resource_id . '_' . DateTime->now->iso8601 . '.txt"');
                return $c->detach();
            }
            elsif (my $upload = $c->req->upload('file')) {

                eval {

                    # Grab the title list upload and copy it to the right place

                    my $upload_dir = $CUFTS::Config::CUFTS_TITLE_LIST_UPLOAD_DIR;

                    my ($sec, $min, $hour, $mday, $mon, $year, $wday) = localtime(time);
                    $mon += 1;
                    $year += 1900;

                    my $filename = $upload_dir . "/overlay_${resource_id}_${year}-${mon}-${mday}_${hour}-${min}-${sec}";

                    $upload->copy_to($filename) or
                        die("Unable to copy title list file '$filename': $!");


                    my $job = $c->job_queue->add_job({
                        info              => "Local title list overlay ($resource_id): " . $global_resource->name,
                        class             => 'local title list overlay',
                        type              => 'local resource',
                        local_resource_id => $resource_id,
                        data              => {
                            file       => $filename,
                            type       => $c->form->valid('type'),
                            match      => $c->form->valid('match'),
                            deactivate => $c->form->valid('deactivate') ? 1 : 0,
                        },
                    });
                    if ( !defined $job ) {
                        die( $c->loc('Unable to create job.') );
                    }

                    push @{$c->stash->{results}}, $c->loc('Title list uploaded and submitted to job queue.');
                };
                if ($@) {
                    $c->stash->{errors} = [ $@ ];
                    warn( $c->loc('Transaction failed: ') . $@ );
                }
            }
        }
    }

    $c->stash->{lr_page}  = $c->form->valid('lr_page');
    $c->stash->{template} ||= 'local_resources/titles/bulk_global.tt';
}


sub _build_export_data {
    my ( $self, $c ) = @_;

    my $local_resource      = $c->stash->{local_resource};
    my $global_resource     = $c->stash->{global_resource};
    my $local_titles_rs     = $c->stash->{local_titles_rs};
    my $global_titles_rs    = $c->stash->{global_titles_rs};
    my $ltg_field           = $global_resource->do_module('local_to_global_field');

    my ( @columns, $titles_rs, @data );
    if ( defined $global_resource && defined $local_resource ) {
        @columns = grep { $_ ne 'id' } @{$global_resource->do_module('title_list_fields')};
        $titles_rs = $local_titles_rs->search(
            {
                'me.resource' => $local_resource->id,
                'me.active'   => 't',
            },
            {
                prefetch => [ $ltg_field ],
            }
        );

        @data = [ @columns ];
        while ( my $title = $titles_rs->next ) {
            push @data, [ map {
                my $cd = $_ . '_display';
                ( $title->can($cd) ? $title->$cd : $title->$_ ) || ( $title->$ltg_field->can($cd) ? $title->$ltg_field->$cd : $title->$ltg_field->$_ ) || '';
            } @columns ];
        }

    }
    else {
        if ( defined $global_resource ) {
            @columns = grep { $_ ne 'id' } @{$global_resource->do_module('title_list_fields')};
            $titles_rs = $global_titles_rs->search({ resource => $global_resource->id });
        }
        else {
            @columns = grep { $_ ne 'id' } @{$local_resource->do_module('title_list_fields')};
            $titles_rs = $local_titles_rs->search({ resource => $local_resource->id });

        }

        @data = [ @columns ];
        while ( my $title = $titles_rs->next ) {
            push @data, [ map { my $cd = $_ . '_display'; $title->can($cd) ? $title->$cd : $title->$_ } @columns ];
        }
    }


    return \@data;
}



=head1 AUTHOR

Todd Holbrook

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
