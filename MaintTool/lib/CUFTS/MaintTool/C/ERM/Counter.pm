package CUFTS::MaintTool::C::ERM::Counter;

use strict;
use base 'Catalyst::Base';

use CUFTS::DB::ERMCounterSources;
use CUFTS::COUNTER;

my $form_validate = {
    required => [
        qw(
            name
            type
            version
        )
    ],
    optional => [
        qw(
            submit
            cancel

            erm_sushi
            reference
            email

            next_run_date
            run_start_date
            interval_months

            upload
            file
        )
    ],
    constraints => {
        next_run_date   => qr/^\d{4}-\d{2}-\d{2}$/,
        run_start_date  => qr/^\d{4}-\d{2}-\d{2}$/,
        run_end_date    => qr/^\d{4}-\d{2}-\d{2}$/,
        type            => qr/^[jd]$/,
    },
    filters  => ['trim'],
    missing_optional_valid => 1,
};

my $form_delete_counts_validate = {
    required => [
        qw(
            counter_source
            delete
            delete_counts
        )
    ],
};

sub default : Private {
    my ( $self, $c ) = @_;

    if ( $c->req->params->{submit} ) {
        my $id = $c->req->params->{source_id};

        if ( $id eq 'new' ) {
            $c->redirect('/erm/counter/edit/new');
        }
        else {
            $c->redirect("/erm/counter/edit/$id");
        }
    }

    my @records = CUFTS::DB::ERMCounterSources->search( site => $c->stash->{current_site}->id, { order_by => 'LOWER(name)' } );
    $c->stash->{records} = \@records;
    $c->stash->{template} = "erm/counter/find.tt";

    return 1;
}

# find_json - Gets a list of source keys and ids starting with the passed in key.  This is used for ExtJS
#             combo box lookups, but could be expanded out to cover other uses.

sub find_json : Local {
    my ( $self, $c ) = @_;

    my @records;
    my $search = { site => $c->stash->{current_site}->id };

    if ( my $key = $c->req->params->{key} ) {
        $search->{key} = { ilike => "$key\%" };
    }

    @records = CUFTS::DB::ERMCounterSources->search( $search, { order_by => 'LOWER(key)' } );

    $c->stash->{json}->{rowcount} = scalar(@records);

    # TODO: Move this to the DB module later.
    $c->stash->{json}->{results}  = [ map { { id => $_->id, key => $_->key } } @records ];

    $c->forward('V::JSON');
}


sub edit : Local {
    my ( $self, $c, $source_id  ) = @_;

    $c->req->params->{cancel}
        and return $c->redirect('/erm/counter/');

    my $source;
    if ( $source_id ne 'new' && int($source_id) > 0 ) {
        $source = CUFTS::DB::ERMCounterSources->search({
            id   => int($source_id),
            site => $c->stash->{current_site}->id,
        })->first;

        if ( !defined($source) ) {
            die("Unable to find Counter Sources record: $source_id for site " . $c->stash->{current_site}->id);
        }
    }

    my @erm_sushi_options = CUFTS::DB::ERMSushi->search({ site => $c->stash->{current_site}->id }, { order_by => 'LOWER(name)' });


    if ( $c->req->params->{submit} ) {

        $c->form( $form_validate );

        unless ( $c->form->has_missing || $c->form->has_invalid || $c->form->has_unknown ) {

            eval {
                if ( $source ) {
                    $source->update_from_form( $c->form );
                }
                else {
                    $c->form->valid->{site} = $c->stash->{current_site}->id;
                    $source = CUFTS::DB::ERMCounterSources->create_from_form( $c->form );
                    $source_id = $source->id;
                }
            };

            if ( $c->form->valid->{file} ) {

                my $upload      = $c->req->upload('file');
                my $fh          = $upload->fh;
                my $schema      = $c->model('CUFTS')->schema;
                my $dbic_source = $c->model('CUFTS::ERMCounterSources')->find({ id => $source->id });

                CUFTS::COUNTER::load_report( $dbic_source, $fh, 0, $schema );

            }

            if ($@) {
                my $err = $@;
                CUFTS::DB::DBI->dbi_rollback;
                die($err);
            }

            CUFTS::DB::DBI->dbi_commit;
            push @{ $c->stash->{results} }, 'ERM COUNTER Source updated.';
        }
    }

#    _get_stats_summary($c,$source);

    $c->stash->{erm_sushi_options} = \@erm_sushi_options;
    $c->stash->{source}     = $source;
    $c->stash->{source_id}  = $source_id;
    $c->stash->{template}   = 'erm/counter/edit.tt';

}

sub delete : Local {
    my ( $self, $c ) = @_;

    $c->form({
        required => [ qw( source_id ) ],
        optional => [ qw( confirm cancel delete ) ],
    });

    unless ( $c->form->has_missing || $c->form->has_invalid || $c->form->has_unknown ) {

        if ( $c->form->valid->{cancel} ) {
            return $c->redirect('/erm/counter/edit/' . $c->form->valid->{source_id} );
        }

        my $source = CUFTS::DB::ERMCounterSources->search({
            site => $c->stash->{current_site}->id,
            id   => $c->form->valid->{source_id},
        })->first;

        my @erm_mains = CUFTS::DB::ERMMain->search( { 'counter_source_links.counter_source' => $source->id }, { join => 'counter_source_links', distinct => 1 } );

        $c->stash->{erm_mains} = \@erm_mains;
        $c->stash->{source}    = $source;

        if ( defined($source) ) {

            if ( $c->form->valid->{confirm} ) {

                eval {
                    $source->delete();
                };

                if ($@) {
                    my $err = $@;
                    CUFTS::DB::DBI->dbi_rollback;
                    die($err);
                }

                CUFTS::DB::ERMMain->dbi_commit();
                $c->stash->{result} = "ERM Counter record deleted.";
            }
        }
        else {
            $c->stash->{error} = "Unable to locate ERM record: " . $c->form->valid->{source_id};
        }

    }

    $c->stash->{template} = 'erm/counter/delete.tt';
}

# Returns JSON results for a simple name search.  This is used to drive AJAX (ExtJS) result lists

sub find_json : Local {
    my ( $self, $c ) = @_;

    my $params = $c->req->params;
    my $options = { order_by => 'LOWER(name)' };

    my %search = ( site => $c->stash->{current_site}->id );
    if (my $term = $params->{name}) {
        $term =~ s/([%_])/\\$1/g;
        $term =~ s#\\#\\\\\\\\#;
        $search{name} = { 'ilike' => "\%$term\%" };
    }
    if (my $term = $params->{type}) {
        $search{type} = $term;
    }
    if (my $term = $params->{erm_main}) {
        $options->{join} = 'counter_links';
        $search{'counter_links.erm_main'} = $term;
    }

    $options->{rows} = $params->{limit} || 1000;  # Hard limit, too many means something is probably wrong
    $options->{page} = ( $params->{start} || 0 / $options->{rows} ) + 1;

    my ($pager, $iterator) = CUFTS::DB::ERMCounterSources->page( \%search, $options );
    my @sources;
    while ( my $source = $iterator->next ) {
        push @sources, $source;
    }

    $c->stash->{json} = {
        success  => 'true',
        rowcount => $pager->total_entries,
        results  => [ map { {id => $_->id, name => $_->name, type => $_->type } } @sources ],
    };

    $c->forward('V::JSON');
}


sub stats_summary : Local {
    my ( $self, $c, $source_id  ) = @_;

    my $source = CUFTS::DB::ERMCounterSources->search({
        id   => int($source_id),
        site => $c->stash->{current_site}->id,
    })->first;
    if ( !defined($source) ) {
        die("Unable to find Counter Sources record: $source_id for site " . $c->stash->{current_site}->id);
    }

    _get_stats_summary($c,$source);

    $c->stash->{source}    = $source;
    $c->stash->{template}  = 'erm/counter/summary.tt';
}

sub _get_stats_summary {
    my ( $c, $source ) = @_;

    my @summaries = CUFTS::DB::ERMCounterCounts->search_stats_by_counter_source( $source->id );
    my %summary_split;
    foreach my $summary ( @summaries ) {
        my $year  = int(substr( $summary->start_date, 0, 4));
        my $month = int(substr( $summary->start_date, 5, 2));
        $summary_split{$year} = {} if !exists($summary_split{$year});
        $summary_split{$year}{$month} = $summary->count;
    }

    $c->stash->{summaries} = \%summary_split;
}

sub delete_counts : Local {
    my ( $self, $c ) = @_;

    if ( $c->req->params->{delete} ) {

        $c->form( $form_delete_counts_validate );

        my $source_id = $c->form->valid->{counter_source};

        my $source = CUFTS::DB::ERMCounterSources->search({
            id   => int($source_id),
            site => $c->stash->{current_site}->id,
        })->first;
        if ( !defined($source) ) {
            die("Unable to find Counter Sources record: $source_id for site " . $c->stash->{current_site}->id);
        }

        my $years = $c->form->valid->{delete_counts};
        if ( ref($years) ne 'ARRAY' ) {
            $years = [ $years ];
        }

        foreach my $year ( @$years ) {
            CUFTS::DB::ERMCounterCounts->search({
                counter_source => $source->id,
                start_date => { '-between' => [ $year . '-01-01', $year . '-12-31' ] },
            })->delete_all;
        }

        if ($@) {
            my $err = $@;
            CUFTS::DB::DBI->dbi_rollback;
            die($err);
        }

        CUFTS::DB::DBI->dbi_commit();
        $c->stash->{results} = ["ERM Counter count records deleted."];

        $c->forward('stats_summary', [$source->id] );

    }

}

1;
