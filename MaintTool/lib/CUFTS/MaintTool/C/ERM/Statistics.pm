package CUFTS::MaintTool::C::ERM::Statistics;

use strict;
use base 'Catalyst::Base';

use JSON::XS qw( encode_json );
use DateTime;
use DateTime::Format::ISO8601;
use Date::Calc;
use Chart::OFC;

use Data::Dumper;

use CUFTS::Util::Simple;

use CUFTS::DB::ERMMain;

my @chart_colours = (
    'red',
    'blue',
    'green',
    'purple',
    'yellow',
    'black',
);

sub auto : Private {
    my ( $self, $c ) = @_;

    my @resources;
    if ( $c->session->{selected_erm_main} && scalar( @{$c->session->{selected_erm_main}} ) ) {
        @resources = CUFTS::DB::ERMMain->search(
            {
                id => { '-in' => $c->session->{selected_erm_main} },
                site => $c->stash->{current_site}->id,
            },
            {
                sql_method => 'with_name',
                order_by => 'result_name',
            }
        );
    }
    my @resources_sorted = map { $_->id } sort { $a->key cmp $b->key } @resources;
    my %resources_map    = map { $_->id => $_ } @resources;

    my @standard_fields = qw( start_date end_date granularity format );

    $c->stash->{report_config} = {
        clickthroughs => {
            id     => 'clickthroughs',
            fields => \@standard_fields,
            uri    => $c->stash->{url_base} . '/erm/statistics/clickthroughs',
        },
        usage_cost => {
            id     => 'usage_cost',
            fields => [qw( start_date end_date format )],
            uri    => $c->stash->{url_base} . '/erm/statistics/usage_cost',
        },
        counter_journal_usage => {
            id     => 'counter_journal_usage',
            fields => [qw( start_date end_date format )],
            uri    => $c->stash->{url_base} . '/erm/statistics/counter_journal_usage',
        },
        counter_database_usage => {
            id     => 'counter_database_usage',
            fields => [qw( start_date end_date format )],
            uri    => $c->stash->{url_base} . '/erm/statistics/counter_database_usage',
        },
        counter_database_usage_from_jr => {
            id     => 'counter_database_usage_from_jr',
            fields => [qw( start_date end_date granularity format )],
            uri    => $c->stash->{url_base} . '/erm/statistics/counter_database_usage_from_jr',
        },
        counter_database_cost_per_use => {
            id     => 'counter_database_cost_per_use',
            fields => [qw( start_date end_date format )],
            uri    => $c->stash->{url_base} . '/erm/statistics/counter_database_cost_per_use',
        },
     };

    $c->stash->{resources}          = \@resources;
    $c->stash->{resources_map}      = \%resources_map;
    $c->stash->{resources_sorted}   = \@resources_sorted;

    return 1;
}


sub default : Private {
    my ( $self, $c ) = @_;

    $c->stash->{template} = "erm/statistics/menu.tt";
}



sub clickthroughs : Local {
    my ( $self, $c ) = @_;

    $c->form({
        optional => [ qw( run_report ) ],
        required => [ qw( selected_resources start_date end_date granularity format ) ],
        constraints => {
            start_date  => qr/^\d{4}-\d{1,2}-\d{1,2}/,
            end_date    => qr/^\d{4}-\d{1,2}-\d{1,2}/,
        },
    });

    if ( $c->form->has_missing || $c->form->has_invalid || $c->form->has_unknown ) {
        return $c->forward('default');
    }

    my $format      = $c->form->{valid}->{format};
    my $granularity = $c->form->{valid}->{granularity};
    my $start_date  = $c->form->{valid}->{start_date};
    my $end_date    = $c->form->{valid}->{end_date};

    my @resource_ids = split(',', $c->form->{valid}->{selected_resources} );

    my $uses = CUFTS::DB::ERMUses->count_grouped( $granularity, $start_date, $end_date, \@resource_ids );

    my @resource_names = CUFTS::DB::ERMNames->search( { erm_main => {'-in' => \@resource_ids}, main => 1 }, { order_by => 'search_name'} );
    $c->stash->{resources} = [ map { { id => $_->erm_main, name => $_->name } } @resource_names ];

    my $dates = _build_granulated_dates( $start_date, $end_date, $granularity );

    # Build two hashes of the results, one keyed on date the other on resource

    my ( %date_hash, %resource_hash );
    my $max = 0;
    foreach my $use ( @$uses ) {
        my ( $resource_id, $count, $date ) = @$use;
        $resource_hash{$resource_id}->{$date} = $count;
        $date_hash{$date}->{$resource_id} = $count;
        if ( $count > $max ) {
            $max = $count;
        }
    }

    $c->stash->{resources_hash}   = \%resource_hash;
    $c->stash->{dates_hash}       = \%date_hash;
    $c->stash->{clickthrough_max} = $max;

    $c->stash->{dates}         = $dates;
    $c->stash->{start_date}    = $c->form->valid->{start_date};
    $c->stash->{end_date}      = $c->form->valid->{end_date};

    if ( $format eq 'html' ) {
        $c->stash->{template} = 'erm/statistics/clickthroughs/html.tt';
    }
    elsif ( $format eq 'tab' ) {
        $c->response->content_type('text/plain');
        $c->stash->{template} = 'erm/statistics/clickthroughs/tab.tt';
    }
    elsif ( $format eq 'graph' ) {
        $c->forward( 'clickthrough_ofc' );
    }
}


sub clickthrough_ofc : Private {
    my ( $self, $c ) = @_;


    my $stash = $c->stash;

    my $x_axis = Chart::OFC::XAxis->new(
        axis_label  => 'Date',
        labels      => [ map { $_->{display} } @{$stash->{dates}} ],
    );
    my $y_axis = Chart::OFC::YAxis->new(
        axis_label  => 'Clickthroughs',
        max         => $stash->{clickthrough_max} || 1,
        label_steps => int( ($stash->{clickthrough_max} || 1) / 10 ) || 1,
    );

    my @dates = map { $_->{date} } @{$stash->{dates}};

    my @chart_data;
    my $count = 0;
    foreach my $resource ( @{$stash->{resources}} ) {
        push @chart_data, Chart::OFC::Dataset::LineWithDots->new(
            color       => $chart_colours[$count++],
            label       => $resource->{name},
            solid_dots  => 1,
            values      => [ map { $stash->{resources_hash}->{$resource->{id}}->{$_} } @dates ],
        );
    }

    my $grid = Chart::OFC::Grid->new(
        title       => 'ERM Clickthroughs',
        datasets    => \@chart_data,
        x_axis      => $x_axis,
        y_axis      => $y_axis,
    );

    $c->flash->{ofc} = $grid->as_ofc_data;

    # Calculate a width/height that will allow all data points to be seen (hopefully)

    $c->stash->{chart_width} = 250 + scalar( @{$stash->{dates}} ) * 50;

    $c->stash->{template} = 'erm/statistics/ofc.tt';
    $c->stash->{data_url} = $c->uri_for('ofc_flash');
}


# types is an array ref of types to match on.  Typically ['requests'] for journals and ['searches', 'sessions'] for databases

sub _counter_usage_generic {
    my ( $self, $c, $types, $report_dir ) = @_;

    $c->form({
        optional => [ qw( run_report selected_resources counter_sources ) ],
        required => [ qw( start_date end_date format ) ],
        constraints => {
            start_date  => qr/^\d{4}-\d{1,2}-\d{1,2}/,
            end_date    => qr/^\d{4}-\d{1,2}-\d{1,2}/,
        },
    });

    if ( $c->form->has_missing || $c->form->has_invalid || $c->form->has_unknown ) {
        return $c->forward('default');
    }

    my $format      = $c->form->{valid}->{format};
    my $start_date  = $c->stash->{start_date} = $c->form->{valid}->{start_date};
    my $end_date    = $c->stash->{end_date}   = $c->form->{valid}->{end_date};

    my $dates = _build_granulated_dates( $start_date, $end_date, 'month', 1 );

    my @counter_sources;
    if ( defined($c->form->{valid}->{counter_sources}) ) {
        @counter_sources = $c->form->{valid}->{counter_sources};
    }
    else {
        my @resource_ids = split(',', $c->form->{valid}->{selected_resources} );
        my @erms = CUFTS::DB::ERMMain->search(
            {
                id => { '-in' => \@resource_ids },
            }
        );

        # TODO: Check that we have some records in @erm here.

        my %counter_sources;
        foreach my $erm (@erms) {
            foreach my $source ( $erm->counter_sources ) {
                $counter_sources{$source->id}++;
            }
        }
        @counter_sources = keys %counter_sources;
    }

    # TODO: This stuff can be rewritten to be hopefully much faster under DBIC by
    #       not going through all the object generation stuff when really we're just after
    #       a couple of numbers

    # Build two hashes of the results, one keyed on date the other on record

    my $records = CUFTS::DB::ERMCounterCounts->search(
        {
            counter_source => { '-in' => \@counter_sources },
            '-and' => [
                start_date => { '>=' => $start_date },
                start_date => { '<=' => $end_date },
            ],
            type => { '-in' => $types },
        },
        {
            prefetch => [ 'counter_title', 'counter_source' ],
        }
    );


    my ( %date_hash, %record_hash, %titles );
    while ( my $record = $records->next ) {

        my $record_id = $record->get('counter_title'); #->id;
        my $date      = $record->start_date;
        my $count     = $record->count;
        my $type      = $record->type;

        $record_hash{$record_id}->{$date}->{$type}->{count} += $count;
        $record_hash{$record_id}->{$date}->{$record->get('counter_source')}->{$type} += $count;
        $record_hash{$record_id}->{$type}->{total} += $count;
        $date_hash{$date}->{$record_id} += $count;
        if ( !exists $titles{$record_id} ) {
            $titles{$record_id} = $record->counter_title->title;
        }
    }

    my @sorted_titles;
    while ( my ( $k, $v ) = each %titles ) {
        push @sorted_titles, [ lc($k), $v ];
    }
    @sorted_titles = sort { $a->[1] cmp $b->[1] } @sorted_titles;

    #
    # use Data::Dumper;
    # warn(Dumper(\%record_hash));
    # warn(Dumper($dates));

    # TODO: Other report formats

    my $template = 'html.tt'; # default
    if ( $format eq 'tab' ) {
        $c->response->content_type('text/plain');
        $template = 'tab.tt';
    }

    $c->stash->{counter_sources} = \@counter_sources;
    $c->stash->{template}        = 'erm/statistics/' . $report_dir . '/' . $template;
    $c->stash->{titles}          = \%titles;
    $c->stash->{sorted_titles}   = \@sorted_titles;
    $c->stash->{dates}           = $dates;
    $c->stash->{records_hash}    = \%record_hash;
    $c->stash->{dates_hash}      = \%date_hash;
    $c->stash->{types}           = $types;
}

sub counter_journal_usage : Local {
    my ( $self, $c ) = @_;

    return $self->_counter_usage_generic( $c, [ 'requests' ], 'counter_journal_usage' )
}

sub counter_database_usage : Local {
    my ( $self, $c ) = @_;
    return $self->_counter_usage_generic( $c, [ 'sessions', 'searches', 'sessions federated', 'searches federated' ], 'counter_database_usage' )
}


sub counter_database_usage_from_jr : Local {
    my ( $self, $c ) = @_;

    $c->form({
        optional => [ qw( run_report ) ],
        required => [ qw( selected_resources start_date end_date granularity format ) ],
        constraints => {
            start_date  => qr/^\d{4}-\d{1,2}-\d{1,2}/,
            end_date    => qr/^\d{4}-\d{1,2}-\d{1,2}/,
        },
    });

    if ( $c->form->has_missing || $c->form->has_invalid || $c->form->has_unknown ) {
        return $c->forward('default');
    }

    my $format      = $c->form->{valid}->{format};
    my $granularity = $c->form->{valid}->{granularity};
    my $start_date  = $c->form->{valid}->{start_date};
    my $end_date    = $c->form->{valid}->{end_date};

    my @resource_ids = split(',', $c->form->{valid}->{selected_resources} );


    my %sources_used;
    my %counts_by_resource;
    foreach my $erm ( @{$c->stash->{resources}} ) {
        foreach my $source ( $erm->counter_sources ) {
            next if $source->type ne 'j';

            push @{$sources_used{$erm->id}}, $source->name;
            my $records = $source->database_usage_from_jr1( $start_date, $end_date );
            foreach my $record ( @$records ) {
                my $date = DateTime::Format::ISO8601->parse_datetime($record->{start_date})->truncate( to => $granularity )->ymd;
                $counts_by_resource{$erm->id}->{$date} += $record->{count};
            }
        }
    }

    my $dates = _build_granulated_dates( $start_date, $end_date, $granularity, 1 );

    $c->stash->{dates}              = $dates;
    $c->stash->{start_date}         = $c->form->valid->{start_date};
    $c->stash->{end_date}           = $c->form->valid->{end_date};
    $c->stash->{counts_by_resource} = \%counts_by_resource;
    $c->stash->{sources_used}       = \%sources_used;

    if ( $format eq 'html' ) {
        $c->stash->{template} = 'erm/statistics/counter_database_usage_from_jr/html.tt';
    }
    elsif ( $format eq 'tab' ) {
        $c->response->content_type('text/plain');
        $c->stash->{template} = 'erm/statistics/counter_database_usage_from_jr/tab.tt';
    }
    elsif ( $format eq 'graph' ) {
#        $c->forward( 'clickthrough_ofc' );
    }
}


# Work out cost per use for journals based on cost data and COUNTER statistics.
# This assumes you'll be using it against sets of individual journal subscriptions

sub counter_database_cost_per_use : Local {
    my ( $self, $c ) = @_;

    $c->form({
        optional => [ qw( run_report ) ],
        required => [ qw( selected_resources start_date end_date format ) ],
        constraints => {
            start_date  => qr/^\d{4}-\d{1,2}-\d{1,2}/,
            end_date    => qr/^\d{4}-\d{1,2}-\d{1,2}/,
        },
    });

    if ( $c->form->has_missing || $c->form->has_invalid || $c->form->has_unknown ) {
        return $c->forward('default');
    }

    my $format      = $c->form->{valid}->{format};
    my $start_date  = $c->stash->{start_date} = $c->form->{valid}->{start_date};
    my $end_date    = $c->stash->{end_date}   = $c->form->{valid}->{end_date};

    my $dates = _build_granulated_dates( $start_date, $end_date, 'year', 1 );

    my @resource_ids = split(',', $c->form->{valid}->{selected_resources} );

    my @erms = CUFTS::DB::ERMMain->search(
        {
            id => { '-in' => \@resource_ids },
        }
    );

    my %sources_used;
    my %counts_by_resource;
    my %costs;
    foreach my $erm ( @{$c->stash->{resources}} ) {

        # Calculate costs data

        my @adv_costs = map { {
            start => DateTime::Format::ISO8601->parse_datetime($_->period_start),
            end   => DateTime::Format::ISO8601->parse_datetime($_->period_end),
            paid  => $_->paid,
         } } $erm->costs;

        # Cheat for now and just use generic cost field

        foreach my $date ( @$dates ) {
            my $cost_total = 0;
            my $period_end = DateTime->new( year => $date->{dt}->year, month => 12, day => 31 );
            foreach my $cost ( @adv_costs ) {
                if (    ( $date->{dt} >= $cost->{start} && $date->{dt} <= $cost->{end} )
                     || ( $period_end >= $cost->{start} && $period_end <= $cost->{end} ) ) {

                    # Calculate percentage applied to this period

                    my $start = $cost->{start} < $date->{dt} ? $date->{dt} : $cost->{start};
                    my $end = $cost->{end} < $period_end ? $cost->{end} : $period_end;
                    my $days = $start->delta_days( $end )->in_units('days') + 1;
                    my $days_in_year = Date::Calc::Days_in_Year( $date->{dt}->year, 12 );
                    my $pct = $days / $days_in_year;

                    warn( "$start\n$end\n$days\n$days_in_year\n$pct\n");

                    $cost_total += $cost->{paid} * $pct;
                }
            }
            $costs{$erm->id}->{$date->{date}} = $cost_total ? $cost_total : $erm->cost;
        }

        # Get counts from JR reports

        foreach my $source ( $erm->counter_sources ) {
            next if $source->type ne 'j';

            push @{$sources_used{$erm->id}}, $source->name;
            my $records = $source->database_usage_from_jr1( $start_date, $end_date );
            foreach my $record ( @$records ) {
                my $date = DateTime::Format::ISO8601->parse_datetime($record->{start_date})->truncate( to => 'year' )->ymd;
                $counts_by_resource{$erm->id}->{$date} += $record->{count};
            }
        }

    }

    use Data::Dumper;
    warn(Dumper(\%costs));

    # TODO: Other report formats

    my $template = 'html.tt'; # default
    if ( $format eq 'tab' ) {
        $c->response->content_type('text/plain');
        $template = 'tab.tt';
    }

    $c->stash->{template}           = 'erm/statistics/counter_database_cost_per_use/' . $template;
    $c->stash->{dates}              = $dates;
    $c->stash->{costs}              = \%costs;
    $c->stash->{start_date}         = $c->form->valid->{start_date};
    $c->stash->{end_date}           = $c->form->valid->{end_date};
    $c->stash->{counts_by_resource} = \%counts_by_resource;
    $c->stash->{sources_used}       = \%sources_used;
}


sub ofc_flash : Local {
    my ( $self, $c ) = @_;

    $c->response->body( $c->flash->{ofc} );
}


# Builds a list of dates based on the start/end date and granularity.  Dates produced are in "YYYY-MM-DD HH:mm:ss" format

sub _build_granulated_dates {
    my ( $start_date, $end_date, $granularity, $date_only ) = @_;

    my $add_granularity = "${granularity}s";  # week => weeks.  make this more complex if we hit something that's not a trivial map
    my $start_dt = DateTime::Format::ISO8601->parse_datetime($start_date);
    my $end_dt   = DateTime::Format::ISO8601->parse_datetime($end_date);

    my @list = ();
    for (my $dt = $start_dt->clone(); $dt <= $end_dt; $dt->add($add_granularity => 1) ) {
        my $trunc_dt = $dt->clone()->truncate( to => $granularity );
        if ( $date_only ) {
            push @list, { date => $trunc_dt->ymd, display => _truncate_date($trunc_dt, $granularity), dt => $trunc_dt };
        }
        else {
            push @list, { date => ($trunc_dt->ymd . ' ' . $trunc_dt->hms), display => _truncate_date($trunc_dt, $granularity), dt => $trunc_dt };
        }
    }

    return \@list;
}

# Truncates a DateTime for display based on granularity.

sub _truncate_date {
    my ( $date, $granularity ) = @_;

    if ( $granularity eq 'year' ) {
        return $date->year;
    }
    elsif ( $granularity eq 'month' ) {
        return $date->strftime('%Y-%m');
    }
    elsif ( $granularity eq 'day' ) {
        return $date->ymd;
    }
    else {
        return $date->ymd . ' ' . $date->hms
    }
}


1;
