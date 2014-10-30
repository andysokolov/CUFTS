package CUFTS::MaintTool::C::Global;

use strict;
use base 'Catalyst::Base';

my $form_validate = {
    required => ['name', 'resource_type', 'module'],
    optional => [
        # Standard fields
        'key', 'provider', 'active', 'submit', 'cancel',
        # Resource details...
        'resource_identifier', 'database_url', 'auth_name', 'auth_passwd', 'url_base', 'notes_for_local', 'proquest_identifier'
    ],
    defaults => { 'active' => 'false' },
    filters  => ['trim'],
    missing_optional_valid => 1,
};

my $form_validate_menu = {
    optional => ['show', 'filter', 'apply_filter', 'sort'],
    filters  => ['trim'],
};

my $form_validate_titles = {
    optional => ['page', 'filter', 'display_per_page', 'apply_filter'],
    filters  => ['trim'],
    defaults => { 'filter' => '', 'page' => 1 },
};

my $form_validate_bulk = {
    required => ['file', 'upload'],
};

my $form_validate_edit_title = {
    optional => ['title_id', 'paging_page', 'apply', 'cancel', ],
    filters  => ['trim'],
    missing_optional_valid => 1,
};

sub auto : Private {
    my ($self, $c, $resource_id) = @_;

    $c->stash->{current_account}->{edit_global} || $c->stash->{current_account}->{administrator} or
        die('User not authorized for global editting');

    if (defined($resource_id) && $resource_id != 0) {
        $c->stash->{resource} = CUFTS::DB::Resources->retrieve($resource_id);
        defined($c->stash->{resource}) or
            die("Unable to load resource: $resource_id");
    }

    $c->stash->{header_section} = 'Global Resources';

    return 1;
}

sub menu : Local {
    my ($self, $c) = @_;

    $c->form($form_validate_menu);

    $c->form->valid->{show} and
        $c->session->{global_menu_show} = $c->form->valid->{show};

    $c->form->valid->{apply_filter} and
        $c->session->{global_menu_filter} = $c->form->valid->{filter};

    $c->form->valid->{sort} and
        $c->session->{global_menu_sort} = $c->form->valid->{sort};

    my %search;
    if ($c->session->{global_menu_filter}) {
        my $filter = $c->session->{global_menu_filter};
        $filter =~ s/([%_])/\\$1/g;
        $filter =~ s#\\#\\\\\\\\#;

        $search{-nest} =
            [
             name => { ilike => "\%$filter\%" },
             provider => { ilike => "\%$filter\%" },
            ];
    }

    defined($c->session->{global_menu_show}) && $c->session->{global_menu_show} eq 'show active' and
        $search{active} = 'true';

    my $search_options = {
        order_by => 'LOWER(name)',
    };

    if ( defined($c->session->{global_menu_sort}) ) {
        if ( $c->session->{global_menu_sort} eq 'provider' ) {
            $search_options->{order_by} = 'LOWER(provider), LOWER(name)';
        }
        elsif ( $c->session->{global_menu_sort} eq 'scanned' ) {
            $search_options->{order_by} = 'title_list_scanned, LOWER(name)';
        }
    }

    my @resources = scalar(keys %search) > 0
                    ? CUFTS::DB::Resources->search_where(\%search, $search_options)
                    : CUFTS::DB::Resources->search({}, $search_options);

    # Delete the title list filter, it should be clear when we go to
    # browse a new list

    delete $c->session->{global_titles_filter};

    $c->stash->{sort} = $c->session->{global_menu_sort};
    $c->stash->{filter} = $c->session->{global_menu_filter};
    $c->stash->{show} = $c->session->{global_menu_show} || 'show all';
    $c->stash->{resources} = \@resources;
    $c->stash->{template} = 'global/menu.tt';
}

sub view : Local {
    my ($self, $c, $resource_id) = @_;

    defined($c->stash->{resource}) or
        return die('No resource loaded to view');

    # Find sites with this resource activated

    my @activated;
    foreach my $local_resource ( $c->stash->{resource}->local_resources ) {
        next if !$local_resource->active;
        my $site = $local_resource->site;
        push @activated, [ $site->name, $local_resource->auto_activate, $local_resource->id, $site->email ];
    }

    @activated = sort { lc($a->[0]) cmp lc($b->[0]) } @activated;

    $c->stash->{activated} = \@activated;
    $c->stash->{template} = 'global/view.tt';
}


sub edit : Local {
    my ($self, $c, $resource_id) = @_;

    $c->req->params->{cancel} and
        return $c->redirect('/global/menu');

    my $resource = $c->stash->{resource};

    if ($c->req->params->{submit}) {

        $c->form($form_validate);

        unless ($c->form->has_missing || $c->form->has_invalid || $c->form->has_unknown) {

            eval {
                if (defined($resource)) {
                    $resource->update_from_form($c->form);
                } else {
                    $resource = CUFTS::DB::Resources->create_from_form($c->form);
                }
            };
            if ($@) {
                CUFTS::DB::DBI->dbi_rollback;
                die;
            }

            CUFTS::DB::DBI->dbi_commit;
            return $c->redirect('/global/menu');
        }
    }

    $c->stash->{resource} = $resource;
    $c->stash->{module_list} = [CUFTS::ResourcesLoader->list_modules()];
    $c->stash->{resource_types} = [CUFTS::DB::ResourceTypes->retrieve_all()];
    $c->stash->{template} = 'global/edit.tt';
}


sub delete : Local {
    my ($self, $c, $resource_id) = @_;

    my $resource = $c->model('CUFTS::GlobalResources')->find({ id => $c->stash->{resource}->id });
    defined($resource) or
         die('No resource loaded to delete.');

    my $schema = $c->model('CUFTS')->schema;
    $schema->txn_do( sub {
        $resource->do_module('delete_title_list', $schema, $resource, 0);
        $resource->delete();
    });

    $c->redirect('/global/menu');
}

sub titles : Local {
    my ($self, $c, $resource_id) = @_;

    defined($c->stash->{resource}) or
        die('No resource loaded for title list');

    $c->stash->{resource}->do_module('has_title_list') or
        die("This resource does not support title lists.");

    my $titles_module = $c->stash->{resource}->do_module('global_db_module') or
        die("Attempt to view local title list for resource type without local list module.");

    $c->form($form_validate_titles);

    my $search = { resource => $resource_id };

    ##
    ## Set up filter for finding specific titles
    ##

    my $filter;
    if ($c->form->{valid}->{apply_filter}) {
        $filter = $c->form->{valid}->{filter};
        if ( $filter ne ( $c->session->{global_titles_filter} || '' ) ) {
            $c->form->{valid}->{page} = 1;
        }
        $c->session->{global_titles_filter} = $filter;
    } else {
        $filter = $c->session->{global_titles_filter};
    }

    if ($filter) {
        $filter =~ s/([%_])/\\$1/g;
        $filter =~ s#\\#\\\\\\\\#;
        $search->{-nest} = $c->stash->{resource}->do_module('filter_on', $filter);
    }

    ##
    ## Set up paging information, create pager and get records
    ##

    my $page = $c->form->{valid}->{page};
    my $order_by = 'title';  # Hardcode for now, allow for other sorts later?
    my $display_per_page = $c->form->{valid}->{display_per_page} || $c->config->{default_display_per_page};

    my ( $pager, $iterator ) = $titles_module->pager($search,
                                                     { order_by => $order_by,
                                                       rows     => $display_per_page,
                                                       page     => $page }
                                                    );

    my @titles;
    while (my $title = $iterator->next) {
        push @titles, $title;
    }
    my $count = $pager->total_entries;

    ##
    ## Fill in stash for templates
    ##

    $c->stash->{paging_count}    = $count;
    $c->stash->{paging_page}     = $page;
    $c->stash->{paging_per_page} = $display_per_page;

    $c->stash->{titles}   = \@titles;
    $c->stash->{filter}   = $c->session->{global_titles_filter};
    $c->stash->{template} = 'global/titles.tt';
}

sub bulk : Local {
    my ($self, $c, $resource_id) = @_;

    defined($c->stash->{resource}) or
        die('No resource loaded for bulk loading');

    if ($c->req->params->{upload}) {

        $c->form($form_validate_bulk);

        unless ($c->form->has_missing || $c->form->has_invalid || $c->form->has_unknown) {

            if (my $upload = $c->req->upload('file')) {

                # Grab the title list upload and copy it to the right place

                my $upload_dir = $CUFTS::Config::CUFTS_TITLE_LIST_UPLOAD_DIR;

                my ($sec, $min, $hour, $mday, $mon, $year, $wday) = localtime(time);
                $mon += 1;
                $year += 1900;

                my $filename = "titles_${resource_id}_${year}-${mon}-${mday}_${hour}-${min}-${sec}";

                $upload->copy_to("${upload_dir}/${filename}") or
                    die("Unable to copy title list file '${upload_dir}/${filename}': $!");

                # Create the data file

                open (CUFTSDAT, ">${upload_dir}/${filename}.CUFTSdat") or
                    die("Unable to create '${upload_dir}/${filename}.CUFTSdat' file: $!");

                print CUFTSDAT "$resource_id\n";
                print CUFTSDAT $c->stash->{current_account}->id . "\n";
                close CUFTSDAT;

                return $c->redirect('/global/bulkdone');

            }
        }
    }

    $c->stash->{template} = 'global/bulk.tt';
}

sub bulkdone : Local {
    my ($self, $c) = @_;

    $c->stash->{template} = 'global/bulkdone.tt';
}

sub edit_title : Local {
    my ($self, $c, $resource_id) = @_;

    my $resource = $c->stash->{resource};
    my $fields = [ @{$resource->do_module('title_list_fields')} ];
    if ( !grep { $_ eq 'journal_auth' } @$fields ) {
        push @$fields, 'journal_auth';
    }
    $c->stash->{fields} = $fields;

    my %validate = %$form_validate_edit_title;
    push @{$validate{optional}}, @$fields;

    $c->form(\%validate);

    if ($c->form->valid->{cancel}) {
        return $c->redirect('/global/titles/' . $resource->id . '?page=' . $c->form->valid->{paging_page});
    }

    my $title;
    if ( $c->form->valid->{title_id} ) {
        $title = $c->stash->{title} = $resource->do_module('global_db_module')->retrieve($c->form->valid->{title_id});
    }

    if ($c->form->valid->{apply}) {

        eval {
            if (defined($title)) {
                $title->update_from_form($c->form);
            } else {
                $c->form->valid->{resource} = $resource->id;
                $resource->do_module('global_db_module')->create_from_form($c->form);
            }
        };
        if ($@) {
            my $err = $@;
            CUFTS::DB::DBI->dbi_rollback;
            die($err);
        }

        CUFTS::DB::DBI->dbi_commit;

        return $c->redirect('/global/titles/' . $resource->id . '?page=' . $c->form->valid->{paging_page});
    }

    $c->stash->{paging_page} = $c->form->valid->{paging_page};
    $c->stash->{template} = 'global/edit_title.tt';
}



1;
