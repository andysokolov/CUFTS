package CUFTS::MaintTool::C::Local;

use strict;
use base 'Catalyst::Base';

use CUFTS::Util::Simple;
use CUFTS::DB::MergedResources;

my $form_validate_local = {
    required => ['name', 'provider', 'module', 'resource_type'],
    optional => [
        'provider', 'proxy', 'dedupe', 'rank', 'active', 'submit', 'cancel',
        'resource_identifier', 'database_url', 'auth_name', 'auth_passwd', 'url_base', 'notes_for_local', 'cjdb_note', 'proxy_suffix', 'erm_main', 'proquest_identifier'
    ],
    defaults => {
        'active' => 'false',
        'proxy' => 'false',
        'dedupe' => 'false',
        'auto_activate' => 'false',
    },
    filters => ['trim'],
    missing_optional_valid => 1,
};

my $form_validate_global = {
    optional => [
        'proxy', 'dedupe', 'auto_activate', 'rank', 'active', 'submit', 'cancel',
        'resource_identifier', 'database_url', 'auth_name', 'auth_passwd', 'url_base', 'cjdb_note', 'proxy_suffix', 'erm_main'
    ],
    defaults => {
        'active' => 'false',
        'proxy' => 'false',
        'dedupe' => 'false',
        'auto_activate' => 'false',
    },
    filters => ['trim'],
    missing_optional_valid => 1,
};

my $form_validate_menu = {
    optional => ['show', 'filter', 'apply_filter', 'sort'],
    filters => ['trim'],
};

my $form_validate_titles = {
    optional => ['page', 'filter', 'display_per_page', 'apply_filter'],
    filters => ['trim'],
    defaults => { 'filter' => '', 'page' => 1 },
};

my $form_validate_bulk = {
    required => ['file', 'upload'],
};

sub auto : Private {
    my ($self, $c, $resource_id) = @_;

    if (defined($resource_id) && $resource_id =~ /^([gl])(\d+)$/) {
        my ($type, $id) = ($1, $2);

        if ($type eq 'l') {
            $c->stash->{local_resource} = CUFTS::DB::LocalResources->retrieve($id);
            $c->stash->{global_resource} = $c->stash->{local_resource}->resource;
        } else {
            $c->stash->{global_resource} = CUFTS::DB::Resources->retrieve($id);
            $c->stash->{local_resource} = CUFTS::DB::LocalResources->search({site => $c->stash->{current_site}->id, resource => $id})->first;
        }
    }

    $c->stash->{header_section} = 'Local Resources';

    return 1;
}

sub menu : Local {
    my ($self, $c) = @_;

    $c->form($form_validate_menu);

    $c->form->valid->{show} and
        $c->session->{local_menu_show} = $c->form->valid->{show};

    # Default to "show active"

    my $active = !defined($c->session->{local_menu_show}) || $c->session->{local_menu_show} eq 'show active' ? 1 : 0;

    $c->form->valid->{apply_filter} and
        $c->session->{local_menu_filter} = $c->form->valid->{filter};

    $c->form->valid->{sort} and
        $c->session->{local_menu_sort} = $c->form->valid->{sort};

    my %search;
    if ($c->session->{local_menu_filter}) {

        # Get filter and escape SQL LIKE special characters

        my $filter = $c->session->{local_menu_filter};
        $filter =~ s/([%_])/\\$1/g;
        $filter =~ s#\\#\\\\\\\\#;

        $search{-nest} =
            [
             name => {ilike => "\%$filter\%"},
             provider => {ilike => "\%$filter\%"},
            ];
    }

    my @global_resources = CUFTS::DB::Resources->search_where({ %search, active => 'true' });

    $active and
        $search{active} = 'true';

    my @local_resources = $c->session->{local_menu_filter}
                          ? CUFTS::DB::LocalResources->search_where({ -nest => [\%search, {resource => { '!=' => undef }}], site => $c->stash->{current_site}->id })
                          : CUFTS::DB::LocalResources->search_where({ %search, site => $c->stash->{current_site}->id });

    # Merge resources into a resource that we can treat like a real CDBI resource except for DB interaction.

    my $resources = CUFTS::MaintTool::M::MergeResources->merge(\@local_resources, \@global_resources, $active);

    # Delete the title list filter, it should be clear when we go to browse a new list

    delete $c->session->{local_titles_filter};

    # Sort resources before displaying.  Set is too small to bother with Schwartzian Transform
    # Sort reverse numeric by rank (only numeric field so far), by any other field with name being the second
    # sort column, or just by name as default.

    my $sort = $c->session->{local_menu_sort} || 'name';
    if ($sort eq 'rank') {
        @$resources = sort { (int($b->$sort || 0) <=> int($a->$sort || 0)) or lc($a->name) cmp lc($b->name) } @$resources;
    } elsif ($sort ne 'name') {
        @$resources = sort { lc($a->$sort) cmp lc($b->$sort) or lc($a->name) cmp lc($b->name) } @$resources;
    } else {
        @$resources = sort { lc($a->$sort) cmp lc($b->$sort) } @$resources;
    }

    $c->stash->{filter} = $c->session->{local_menu_filter};
    $c->stash->{sort} = $sort;
    $c->stash->{show} = $c->session->{local_menu_show} || 'show active';
    $c->stash->{resources} = $resources;
    $c->stash->{template} = 'local/menu.tt';
}

# Returns JSON results for a simple name search.  This is used to drive AJAX (ExtJS) result lists

sub find_json : Local {
    my ( $self, $c ) = @_;

    my $params = $c->req->params;

    my %search = ( active => 'true', site => $c->stash->{current_site}->id );
    if (my $term = $params->{name}) {
        $term =~ s/([%_])/\\$1/g;
        $term =~ s#\\#\\\\\\\\#;
        $search{name} = { 'ilike' => "\%$term\%" };
    }
    if (my $term = $params->{provider}) {
        $term =~ s/([%_])/\\$1/g;
        $term =~ s#\\#\\\\\\\\#;
        $search{provider} = { 'ilike' => "\%$term\%" };
    }
    if (my $term = $params->{erm_main}) {
        $search{erm_main} = $term;
    }

    my $options = { order_by => 'LOWER(name)' };
    $options->{rows} = $params->{limit} || 1000;  # Hard limit, too many means something is probably wrong
    $options->{page} = ( $params->{start} / $options->{rows} ) + 1;

    my ($pager, $iterator) = CUFTS::DB::MergedResources->page( \%search, $options );
    my @resources;
    while ( my $resource = $iterator->next ) {
        push @resources, $resource;
    }

    $c->stash->{json} = {
        success  => 'true',
        rowcount => $pager->total_entries,
        results  => [ map { {id => $_->id, name => $_->name, provider => $_->provider, erm_main => ($_->erm_main ? $_->erm_main->key : undef) } } @resources ],
    };

    $c->forward('V::JSON');
}


sub view : Local {
    my ($self, $c, $resource_id) = @_;

    if (defined($c->stash->{global_resource})) {
        $c->stash->{template} = 'local/view_global.tt';
    } elsif (defined($c->stash->{local_resource})) {
        $c->stash->{template} = 'local/view_local.tt';
    } else {
        return die('No resource loaded to view');
    }
}


sub edit : Local {
    my ($self, $c, $resource_id) = @_;

    $c->req->params->{cancel} and
        return $c->redirect('/local/menu');

    my $global_resource = $c->stash->{global_resource};
    my $local_resource  = $c->stash->{local_resource};


    $c->form->valid->{site} = $c->stash->{current_site}->id;

    if ($c->req->params->{submit}) {

        $c->form(defined($global_resource) ? $form_validate_global : $form_validate_local);

        unless ($c->form->has_missing || $c->form->has_invalid || $c->form->has_unknown) {

            eval {

                if ( !defined($local_resource) ) {
                    my $new_record = { site => $c->stash->{current_site}->id };

                    if ( defined($global_resource) ) {
                        $new_record->{resource} = $global_resource->id;
                    }
                    else {
                        $new_record->{module}     = 'blank';
                        $new_record->{name}       = 'New Local Resource';
                        $new_record->{provider}   = 'New Provider';
                    }

                    $local_resource = CUFTS::DB::LocalResources->create($new_record);
                    $c->stash->{local_resource} = $local_resource;

                }

                $local_resource->update_from_form($c->form);

                if ($local_resource->auto_activate) {
                    $local_resource->activate_titles();
                }

            };

            if ($@) {
                my $err = $@;
                CUFTS::DB::DBI->dbi_rollback;
                die($err);
            }

            CUFTS::DB::DBI->dbi_commit;

            return $c->redirect('/local/menu');
        }
    }

    # Get all the ERM mains for a select box - switch this to use the search system later

    my $erm_mains = CUFTS::DB::ERMMain->retrieve_all_for_site( $c->stash->{current_site}->id, 1 );    # 1 - fast, no objects
    $c->stash->{erm_mains} = $erm_mains;

    # Fill out the rest of the stash

    $c->stash->{section} = 'general';
    $c->stash->{module_list} = [CUFTS::ResourcesLoader->list_modules()];

    if (defined($global_resource)) {
        $c->stash->{template} = 'local/edit_global.tt';
    } else {
        $c->stash->{resource_types} = [CUFTS::DB::ResourceTypes->retrieve_all()];
        $c->stash->{template} = 'local/edit_local.tt';
    }
}


sub delete : Local {
    my ($self, $c, $resource_id) = @_;

    my $resource = $c->model('CUFTS::LocalResources')->find({ id => $c->stash->{local_resource}->id });
    defined($resource) or
         die('No resource loaded to delete.');

    my $schema = $c->model('CUFTS')->schema;
    $schema->txn_do( sub {
        $resource->do_module('delete_title_list', $schema, $resource, 1);
        $resource->delete();
    });

    $c->redirect('/local/menu');
}


1;
