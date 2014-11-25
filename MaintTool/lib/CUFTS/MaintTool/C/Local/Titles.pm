package CUFTS::MaintTool::C::Local::Titles;

use strict;
use base 'Catalyst::Base';

use List::MoreUtils qw(uniq);

use CUFTS::DB::MergedJournals;

my $form_validate_titles = {
    optional => ['show', 'cancel', 'page', 'filter', 'display_per_page', 'apply_filter', 'apply', 'activate_all', 'deactivate_all', 'edit'],
    optional_regexp => qr/^(new|orig|hide)_.+/,
    filters => ['trim'],
    defaults => { 'filter' => '', 'page' => 1 },
};

my $form_validate_hidden_fields = {
    optional => ['page', 'hidden_fields', 'cancel', 'apply'],
    optional_regexp => qr/^hide_/,
    filters => ['trim'],
};

my $form_validate_single = {
    required => ['global_id'],
    optional => ['paging_page', 'apply' ],
    filters => ['trim'],
    missing_optional_valid => 1,
};

my $form_validate_edit_local = {
    required => ['local_id'],
    optional => ['paging_page', 'apply' ],
    filters => ['trim'],
    missing_optional_valid => 1,
};

my $form_validate_bulk_global_upload = {
    required => ['file', 'upload', 'type', 'deactivate', 'match'],
};

my $form_validate_bulk_global_export = {
    required => ['export', 'format', 'records'],
};

my $form_validate_bulk_local_upload = {
    required => ['file', 'upload'],
};

my $form_validate_bulk_local_export = {
    required => ['format'],
    optional => ['export'],
};

sub edit : Local {
    my ($self, $c) = @_;
    if (defined($c->stash->{global_resource})) {
        $c->stash->{template} = 'local/titles/edit_global.tt';
        $c->forward('/local/titles/manage_global');
    } else {
        $c->stash->{template} = 'local/titles/edit_local.tt';
        $c->forward('/local/titles/manage_local');
    }
}

sub view : Local {
    my ($self, $c) = @_;

    if (defined($c->stash->{global_resource})) {
        $c->stash->{template} = 'local/titles/view_global.tt';
        $c->forward('/local/titles/manage_global');
    } else {
        $c->stash->{template} = 'local/titles/view_local.tt';
        $c->forward('/local/titles/manage_local');
    }
}

sub apply_edit : Local {
    my ($self, $c) = @_;
    $self->apply($c);
    $c->forward('/local/titles/edit');
}

sub apply_view : Local {
    my ($self, $c) = @_;
    $self->apply($c);
    $c->forward('/local/titles/view');
}

sub apply {
    my ($self, $c) = @_;

    $c->form($form_validate_titles);

    my $global_resource = $c->stash->{global_resource};
    my $local_resource = $c->stash->{local_resource};

    eval {
        defined($local_resource) or
            $local_resource = $c->stash->{local_resource} = CUFTS::DB::LocalResources->create({resource => $global_resource->id, site => $c->stash->{current_site}->id});

        my $module = defined($global_resource) ? $global_resource->do_module('local_db_module') : $local_resource->do_module('local_db_module');
        my $merge_field = defined($global_resource) ? $global_resource->do_module('local_to_global_field') : undef;

        my $valid = $c->form->valid;

        if ($valid->{apply}) {
            no strict 'refs';

            my %seen;
            foreach my $param (keys %$valid) {
                next unless $param =~ /^(?:new|orig)_(\d+)_(\w+)$/;
                my ($id, $col) = ($1, $2);

                next if $seen{$id}->{$col}++;

                my $new_val = $valid->{"new_${id}_${col}"};
                my $old_val = $valid->{"orig_${id}_${col}"};

                $col eq 'active' && !defined($new_val) and
                    $new_val = 'false';

                next unless ( (defined($new_val) && !defined($old_val)) ||
                              (!defined($new_val) && defined($old_val)) ||
                              (defined($new_val) && defined($old_val) && $new_val ne $old_val) );


                if (defined($global_resource)) {
                    my $title = $module->search({resource => $local_resource->id, $merge_field => $id})->first;
                    defined($title) or
                        $title = $module->create({resource => $local_resource->id, $merge_field => $id});
                    $title->$col($new_val);
                    $title->update;
                } else {
                    my $title = $module->retrieve($id);
                    $title->$col($new_val);
                    $title->update;
                }
            }
        } elsif ($valid->{activate_all}) {
            $local_resource->activate_titles();
        } elsif ($valid->{deactivate_all}) {
            $local_resource->deactivate_titles();
        }
    };
    if ($@) {
        my $err = $@;
        CUFTS::DB::DBI->dbi_rollback;
        die($err);
    }

    CUFTS::DB::DBI->dbi_commit;
}

sub manage_global : Private {
    my ($self, $c, $resource_id) = @_;

    $c->form($form_validate_titles);

    my $global_resource = $c->stash->{global_resource};
    my $local_resource = $c->stash->{local_resource};

    defined($global_resource) or
        die('No resource loaded for title list');

    $global_resource->do_module('has_title_list') or
        die("This resource does not support title lists.");

    my $global_titles_module = $global_resource->do_module('global_db_module') or
        die("Attempt to view local title list for resource type without global list module.");

    my $local_titles_module = $global_resource->do_module('local_db_module') or
        die("Attempt to view local title list for resource type without local list module.");

    $c->form->valid->{show} and
        $c->session->{local_titles_show} = $c->form->valid->{show};

    my $active = defined($c->session->{local_titles_show}) && $c->session->{local_titles_show} eq 'show active' ? 1 : 0;

    my $search = { resource => $global_resource->id };

    ##
    ## Set up filter for finding specific titles
    ##

    my $filter = $c->form->{valid}->{filter};
    if (    $c->form->{valid}->{apply_filter}
         && $filter ne ($c->session->{local_titles_filter} || '')
       ) {

        $c->form->{valid}->{page} = 1;
        $c->session->{local_titles_filter} = $filter;

    } else {
        $filter = $c->session->{local_titles_filter};
    }

    if ( defined($filter) && $filter ne '' ) {
        $filter =~ s/([%_])/\\$1/g;
        $filter =~ s#\\#\\\\\\\\#;
        $search->{-nest} = $global_resource->do_module('filter_on', $filter);
    }

    ##
    ## Set up paging information, create pager and get records
    ##

    my $page = $c->form->{valid}->{page};
    my $order_by = 'title';  # Hardcode for now, allow for other sorts later?
    my $display_per_page = $c->form->{valid}->{display_per_page} || $c->config->{default_display_per_page};

    my ( $pager, $iterator );
    if (defined($local_resource) && !$local_resource->auto_activate && $active) {
        $search->{local_resource} = $local_resource->id;
        ($pager, $iterator) = $global_resource->do_module('active_global_db_module')
                                 ->pager($search,
                                         { order_by => $order_by,
                                           rows => $display_per_page,
                                           page => $page}
                                        );
    } else {
        ($pager, $iterator) = $global_titles_module->pager($search,
                                         { order_by => $order_by,
                                           rows => $display_per_page,
                                           page => $page}
                                        );
    }

    my $count = $pager->total_entries;
    my @titles;
    while (my $title = $iterator->next) {
        push @titles, $title;
    }

    ##
    ## Get matching local titles if available
    ##

    my @local_titles;
    foreach my $global_title (@titles) {
        if (defined($local_resource)) {
            my @local_search = $local_titles_module->search($global_resource->do_module('local_to_global_field') => $global_title->id, resource => $local_resource->id);
            if (scalar(@local_search) == 1) {
                push @local_titles, $local_search[0];
            } else {
                push @local_titles, undef;
            }
        } else {
            push @local_titles, undef;
        }
    }

    ##
    ## Grab fields to hide if we have a local resource
    ##

    $c->stash->{hidden_fields} = defined($local_resource) ? [$local_resource->hidden_fields] : [];

    ##
    ## Fill in stash for templates
    ##

    $c->stash->{paging_count} = $count;
    $c->stash->{paging_page} = $page;
    $c->stash->{paging_per_page} = $display_per_page;

    $c->stash->{show} = $c->session->{local_titles_show} || 'show all';
    $c->stash->{global_titles} = \@titles;
    $c->stash->{local_titles} = \@local_titles;
    $c->stash->{filter} = $c->session->{local_titles_filter};
}


sub manage_local : Private {
    my ($self, $c, $resource_id) = @_;

    $c->form($form_validate_titles);

    my $local_resource = $c->stash->{local_resource};

    $local_resource->do_module('has_title_list') or
        die("This resource does not support title lists.");

    my $local_titles_module = $local_resource->do_module('local_db_module') or
        die("Attempt to view local title list for resource type without local list module.");

    $c->form->valid->{show} and
        $c->session->{local_titles_show} = $c->form->valid->{show};

    my $active = defined($c->session->{local_titles_show}) && $c->session->{local_titles_show} eq 'show active' ? 1 : 0;

    my $search = { resource => $local_resource->id };

    ##
    ## Set up filter for finding specific titles
    ##

    my $filter = $c->form->{valid}->{filter};
    if (    $c->form->{valid}->{apply_filter}
         && $filter ne ($c->session->{local_titles_filter} || '')
       ) {

        $c->form->{valid}->{page} = 1;
        $c->session->{local_titles_filter} = $filter;

    } else {
        $filter = $c->session->{local_titles_filter};
    }

    if (defined($filter) && $filter ne '') {
        $filter =~ s/([%_])/\\$1/g;
        $filter =~ s#\\#\\\\\\\\#;
        $search->{-nest} = $local_resource->do_module('filter_on', $filter);
    }

    ##
    ## Set up paging information, create pager and get records
    ##

    my $page = $c->form->{valid}->{page};
    my $order_by = 'title';  # Hardcode for now, allow for other sorts later?
    my $display_per_page = $c->form->{valid}->{display_per_page} || $c->config->{default_display_per_page};

    my ($pager, $iterator) = $local_titles_module->pager($search,
                                                         { order_by => $order_by,
                                                           rows => $display_per_page,
                                                           page => $page, }
                                                        );

    my @titles;
    while (my $title = $iterator->next) {
        push @titles, $title;
    }
    my $count = $pager->total_entries;

    ##
    ## Fill in stash for templates
    ##

    $c->stash->{paging_count} = $count;
    $c->stash->{paging_page} = $page;
    $c->stash->{paging_per_page} = $display_per_page;

    $c->stash->{show} = $c->session->{local_titles_show} || 'show all';
    $c->stash->{titles} = \@titles;
    $c->stash->{filter} = $c->session->{local_titles_filter};
}

sub hidden_fields : Local {
    my ($self, $c, $resource_id) = @_;

    my $global_resource = $c->stash->{global_resource};
    my $local_resource = $c->stash->{local_resource};

    $c->form($form_validate_hidden_fields);

    if ($c->form->valid->{apply}) {

        eval {
            defined($local_resource) or
                $local_resource = $c->stash->{local_resource} = CUFTS::DB::LocalResources->create({resource => $global_resource->id, site => $c->stash->{current_site}->id});

            CUFTS::DB::HiddenFields->search(resource => $local_resource->id)->delete_all;

            foreach my $field (keys %{$c->form->{valid}}) {
                next unless $field =~ /^hide_(.+)$/;
                CUFTS::DB::HiddenFields->create({
                    field => $1,
                    resource => $local_resource->id,
                    site => $c->stash->{current_site}->id,
                });
            }
        };
        if ($@) {
            my $err = $@;
            CUFTS::DB::DBI->dbi_rollback;
            die($err);
        }

        CUFTS::DB::DBI->dbi_commit;

        return $c->forward('/local/titles/edit');
    } elsif ($c->form->valid->{cancel}) {
        return $c->forward('/local/titles/edit');
    }

    my @fields = @{$global_resource->do_module('title_list_fields')};
    foreach my $field (@{$global_resource->do_module('overridable_title_list_fields')}) {
        grep {$_ eq $field} @fields or
            push @fields, $field;
    }
    $c->stash->{fields} = \@fields;

    $c->stash->{hidden_fields} = defined($local_resource) ? [$local_resource->hidden_fields] : [];

    $c->stash->{page} = $c->form->valid->{page};
    $c->stash->{template} = 'local/titles/hidden_fields.tt';
}


##
## single - edits a single local title *attached to a global title*.  See edit_local for editing a local only title.
##

sub single : Local {
    my ($self, $c, $resource_id) = @_;

    my $global_resource = $c->stash->{global_resource};
    my $local_resource = $c->stash->{local_resource};
    my $override_fields = $c->stash->{override_fields} = $global_resource->do_module('overridable_title_list_fields');
    my %validate = %$form_validate_single;
    push @{$validate{optional}}, @$override_fields;

    $c->form(\%validate);

    my $global_title = $c->stash->{global_title} = $global_resource->do_module('global_db_module')->retrieve($c->form->valid->{global_id});
    my $local_title;
    defined($local_resource) and
        $local_title = $c->stash->{local_title} = $global_resource->do_module('local_db_module')->search({resource => $local_resource->id, $global_resource->do_module('local_to_global_field') => $global_title->id})->first;

    if ($c->form->valid->{apply}) {
        defined($local_resource) or
            $local_resource = $c->stash->{local_resource} = CUFTS::DB::LocalResources->create({resource => $global_resource->id, site => $c->stash->{current_site}->id});

        eval {
            if (defined($local_title)) {
                $local_title->update_from_form($c->form);
            } else {
                $c->form->valid->{resource} = $local_resource->id;
                $c->form->valid->{$global_resource->do_module('local_to_global_field')} = $global_title->id;
                $local_title = $local_resource->do_module('local_db_module')->create_from_form($c->form);
            }
        };
        if ($@) {
            my $err = $@;
            CUFTS::DB::DBI->dbi_rollback;
            die($err);
        }

        CUFTS::DB::DBI->dbi_commit;

        return $c->redirect('/local/titles/view/g' . $global_resource->id . '?page=' . $c->form->valid->{paging_page});
    }

    $c->stash->{paging_page} = $c->form->valid->{paging_page};
    $c->stash->{template} = 'local/titles/single.tt';
}


# Edit a single local resource

sub edit_local : Local {
    my ($self, $c, $resource_id) = @_;

    my $local_resource = $c->stash->{local_resource};
    my %validate = %$form_validate_edit_local;
    my @fields = uniq( @{$local_resource->do_module('title_list_fields')}, @{$local_resource->do_module('overridable_title_list_fields')} );
    my $override_fields = $c->stash->{override_fields} = \@fields;
    push @{$validate{optional}}, @$override_fields;

    $c->form(\%validate);

    my $local_title = $c->stash->{local_title} = $local_resource->do_module('local_db_module')->search({
        id => $c->form->valid->{local_id},
        resource => $local_resource->id,
    })->first;

    if ($c->form->valid->{apply}) {

        eval {
            if (defined($local_title)) {
                $local_title->update_from_form($c->form);
            } else {
                $c->form->valid->{resource} = $local_resource->id;
                $c->form->valid->{active} = 'true';
                $local_title = $local_resource->do_module('local_db_module')->create_from_form($c->form);
            }
        };
        if ($@) {
            my $err = $@;
            CUFTS::DB::DBI->dbi_rollback;
            die($err);
        }

        CUFTS::DB::DBI->dbi_commit;

        return $c->redirect('/local/titles/view/l' . $local_resource->id . '?page=' . $c->form->valid->{paging_page});
    }

    $c->stash->{paging_page} = $c->form->valid->{paging_page};
    $c->stash->{template} = 'local/titles/edit_local.tt';
}

sub delete_local : Local {
    my ($self, $c, $resource_id) = @_;

    my $local_resource = $c->stash->{local_resource};

    $c->form({required => ['local_id']});

    my $local_title = $c->stash->{local_title} = $local_resource->do_module('local_db_module')->search({
        id => $c->form->valid->{local_id},
        resource => $local_resource->id,
    })->first;

    if ( $local_title ) {
        eval { $local_title->delete; };
        if ($@) {
            my $err = $@;
            CUFTS::DB::DBI->dbi_rollback;
            die($err);
        }

        CUFTS::DB::DBI->dbi_commit;
    }

    return $c->redirect('/local/titles/view/l' . $local_resource->id . '?page=' . $c->form->valid->{paging_page});
}

sub bulk_global : Local {
    my ($self, $c, $resource_id) = @_;

    $c->stash->{template} = 'local/titles/bulk_global.tt';
}

sub bulk_global_upload : Local {
    my ($self, $c, $resource_id) = @_;

    my $global_resource = $c->stash->{global_resource};
    my $local_resource = $c->stash->{local_resource};

    defined($global_resource) or
        die("No global resource loaded for bulk update");

    $c->form($form_validate_bulk_global_upload);

    unless ($c->form->has_missing || $c->form->has_invalid || $c->form->has_unknown) {

        if (my $upload = $c->req->upload('file')) {

            eval {
                defined($local_resource) or
                    $local_resource = $c->stash->{local_resource} = CUFTS::DB::LocalResources->create({resource => $global_resource->id, site => $c->stash->{current_site}->id});
            };
            if ($@) {
                my $err = $@;
                CUFTS::DB::DBI->dbi_rollback;
                die($err);
            }

            CUFTS::DB::DBI->dbi_commit;

            my $method = $c->form->valid->{type} . '_title_list';

            $local_resource  = $c->model('CUFTS::LocalResources')->find({ id => $local_resource->id });
            $global_resource = $c->model('CUFTS::GlobalResources')->find({ id => $global_resource->id });

            my $schema = $c->model('CUFTS')->schema;

            $schema->txn_do( sub {
                $c->stash->{bulk_results} = $global_resource->do_module($method, $schema, $local_resource, $upload->tempname, $c->form->valid->{match}, $c->form->valid->{deactivate});
            });

            $c->stash->{template} = 'local/titles/bulk_global_results.tt';
        }
    } else {
        die("Error in bulk_global_upload form. Validation failed.");
    }
}

sub bulk_global_export : Local {
    my ($self, $c, $resource_id) = @_;

    $c->form($form_validate_bulk_global_export);

    my $global_resource = $c->stash->{global_resource};
    my $local_resource = $c->stash->{local_resource};

    my @global_titles;
    unless ($c->form->has_missing || $c->form->has_invalid || $c->form->has_unknown) {
        if ( $c->form->valid->{records} eq 'active' || $c->form->valid->{records} eq 'overlay' ) {
            @global_titles = $global_resource->do_module('active_global_db_module')->search({local_resource => $local_resource->id, resource => $global_resource->id}, {order_by => 'title'});
        } else {
            @global_titles = $global_resource->do_module('global_db_module')->search({resource => $global_resource->id}, {order_by => 'title'});
        }

        my @local_titles;
TITLE:
        foreach my $global_title (@global_titles) {
            if (defined($local_resource)) {
                my @local_search = $global_resource->do_module('local_db_module')->search($global_resource->do_module('local_to_global_field') => $global_title->id, resource => $local_resource->id);
                if ( scalar(@local_search) == 1 && _check_overlay($c->form->valid->{records}, $local_search[0]) ) {
                    push @local_titles, $local_search[0];
                    next TITLE;
                }
            }

            push @local_titles, undef;
        }

        $c->stash->{global_titles} = \@global_titles;
        $c->stash->{local_titles} = \@local_titles;

        if ( $c->form->valid->{records} eq 'overlay' ) {
            $c->stash->{template} = 'local/titles/export/overlay_' . $c->form->valid->{format} . '.tt';
        }
        else {
            $c->stash->{template} = 'local/titles/export/' . $c->form->valid->{format} . '.tt';
        }
    } else {
        die("Error in bulk_global_export form.  Validation failed.");
    }
}

# Check that we are looking at the overlay report type, and if so that the local record has some changes.

sub _check_overlay {
    my ( $report, $record ) = @_;

    return 1 if $report ne 'overlay'; # Only check for changes if we're in the overlay report

    return $record->has_overlay();

}

sub bulk_local : Local {
    my ($self, $c, $resource_id) = @_;

    my $local_resource = $c->stash->{local_resource};

    $local_resource = $c->model('CUFTS::LocalResources')->find({ id => $local_resource->id });

    defined($local_resource) or
        die("No local resource loaded for bulk update");

    if ($c->req->params->{upload}) {

        $c->form($form_validate_bulk_local_upload);

        unless ($c->form->has_missing || $c->form->has_invalid || $c->form->has_unknown) {

            if (my $upload = $c->req->upload('file')) {

                my $tmp;

                eval {
                    my $schema = $c->model('CUFTS')->schema;
                    $schema->txn_do( sub {
                        $tmp = $local_resource->do_module('load_title_list', $schema, $local_resource, $upload->tempname, 1);
                    });
                };
                if ($@) {
                    $c->stash->{errors} = [ $@ ];
                } else {
                    $c->stash->{bulk_results} = $tmp;
                    $c->stash->{template} = 'local/titles/bulk_local_results.tt';
                }

            }
        }
    }

    $c->stash->{template} ||= 'local/titles/bulk_local.tt';
}


sub bulk_local_export : Local {
    my ($self, $c, $resource_id) = @_;

    $c->form($form_validate_bulk_local_export);

    my $local_resource = $c->stash->{local_resource};

    my @local_titles;
    unless ($c->form->has_missing || $c->form->has_invalid) {
        @local_titles = $local_resource->do_module('local_db_module')->search({resource => $local_resource->id}, {order_by => 'title'});

        $c->stash->{local_titles} = \@local_titles;

        $c->stash->{template} = 'local/titles/export/' . $c->form->valid->{format} . '_local.tt';
    } else {
        die("Error in bulk_local_export form.  Validation failed.");
    }
}


# Returns JSON results for a simple name search.  This is used to drive AJAX (ExtJS) result lists

sub find_json : Local {
    my ( $self, $c ) = @_;
    use Data::Dumper;

    my $params = $c->req->params;

    my %search = ( site => $c->stash->{current_site}->id );
    if (my $term = $params->{title}) {
        $term =~ s/([%_])/\\$1/g;
        $term =~ s#\\#\\\\\\\\#;
        $search{title} = { 'ilike' => "$term\%" };
    }
    if (my $term = uc($params->{issn}) ) {
        $term =~ tr/[0-9X]//cd;
        $search{'-or'} = { issn => $term, e_issn => $term };
    }
    if (my $term = $params->{local_resource}) {
        $search{local_resource} = $term;
    }
    if (my $term = $params->{erm_main}) {
        $search{erm_main} = $term;
    }

    my $options = { order_by => 'LOWER(title)' };
    $options->{rows} = $params->{limit} || 1000;  # Hard limit, too many means something is probably wrong
    $options->{page} = ( $params->{start} / $options->{rows} ) + 1;

    my ($pager, $iterator) = CUFTS::DB::MergedJournals->page( \%search, $options );
    my @resources;
    while ( my $resource = $iterator->next ) {
        push @resources, $resource;
    }

    $c->stash->{json} = {
        success  => 'true',
        rowcount => $pager->total_entries,
        results  => [ map { {id => $_->id, title => $_->title, resource_name => $_->resource_name, erm_main => $_->erm_main_key, issn => $_->issn, e_issn => $_->e_issn } } @resources ],
    };

    $c->forward('V::JSON');
}


1;
