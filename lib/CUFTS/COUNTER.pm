package CUFTS::COUNTER;

use CUFTS::DB::ERMCounterCounts;
use CUFTS::DB::ERMCounterSources;
use CUFTS::DB::ERMCounterTitles;
use CUFTS::DB::JournalsAuth;

use Data::Dumper;
use Biblio::COUNTER;
use HTML::Entities;
use CUFTS::Util::Simple;
use DateTime;

use strict;

my $DEBUG = 1;

# Utility code for working with COUNTER records

sub load_report {
    my ( $source, $report_file ) = @_;

    my $record_number = 0;
    my %callbacks = (
        begin_report => sub {
        },
        end_header => sub {
        },
        end_record => sub {
            if ( $DEBUG ) {
                my ($report, $record) = @_;
                ++$record_number;
                print STDERR "!$record_number! "
                    if $record_number % 10 == 0;
                print STDERR "\n"
                    if $record_number % 100 == 0;
            }
        },
        end_report => sub {
            if ( $DEBUG ) {
                my ($report) = @_;
                if ($report->is_valid) {
                    print STDERR "OK\n";
                }
                else {
                    print STDERR "INVALID\n";
                }
            }
        },
        output => sub {},
        cant_fix => sub {
            my ( $report, $field, $val, $expected ) = @_;
            print STDERR "CANT'T FIX: $field, $val, $expected\n";
        }
    );

    my $report = Biblio::COUNTER->report($report_file, callback => \%callbacks )->process;
    if ( !$report->is_valid ) {
        warn("Biblio::COUNTER was unable to process the report file.");
    }

    my $name = $report->name;

    # Try to find a specific report processor, they're different enough
    # reports that there's no real general case.
    
    if ( $name =~ /Journal\sReport\s1/ || $name =~ /JR1/ ) {
        return load_report_jr1( $source, $report );
    }
    elsif ( $name =~ /Database\sReport\s1/ || $name =~ /DB1/ ) {
        return load_report_db1( $source, $report );
    }
    
    die("Could not find a report processor for: " . $name);
}


# $report should be a Biblio::COUNTER report
sub load_report_jr1 {
    my ( $source, $report ) = @_;
    
    if ( $DEBUG ) {
        warn("Publisher: "  . $report->publisher    . "\n");
        warn("Platform: "   . $report->platform     . "\n");
        warn("Date: "       . $report->date_run     . "\n");
    }
    
    my $periods = $report->periods;
    foreach my $journal ( $report->records ) {

        my $title = $journal->{title};
        $title = decode_entities(decode_entities($title)); # Necessary for Scholarly Stats, at least - decode &amp; in XML, then decode the result to real characters
        next if is_empty_string($title);


        # Stringify, and remove dashes
        my $issn  = "" . $journal->{print_issn};
        my $eissn = "" . $journal->{online_issn};
        $issn  = ($issn  =~ /(\d{4})-?(\d{3}[\dxX])/) ? "$1$2" : undef;
        $eissn = ($eissn =~ /(\d{4})-?(\d{3}[\dxX])/) ? "$1$2" : undef;
    
        # Clean up quotes around title
    
        $title = trim_string($title, '"');
    
        my $journal_data = {
            title  => $title,
            issn   => $issn,
            e_issn => $eissn,
        };
        
        if ( $DEBUG ) {
            warn(Dumper($journal_data) . "\n");
        }
        
        # Find or create a new COUNTER titles record
        my $journal_rec = CUFTS::DB::ERMCounterTitles->search($journal_data)->first;
        if ( !$journal_rec ) {
            ## TODO: Try to find a matching journal auth first?
            $journal_rec = CUFTS::DB::ERMCounterTitles->create($journal_data);
        }
        
        # Loop through the counts and create a COUNTER counts record for each reported period for this journal
        
        my $count  = $journal->{count};
        foreach my $period ( keys %$count ) {
            while ( my ($metric, $num) = each %{ $count->{$period} } ) {
                if ( $DEBUG ) {
                    warn("* $metric: $num\n");
                }

                # Get the start date from the period which comes out as just YYYY-MM from Biblio::COUNTER

                my $start_date;
                if ( $period =~ /^(\d{4})-(\d{2})$/ ) {
                    my ( $year, $month, $day ) = ( $1, $2, 1 );
                    my $start = DateTime->new( year => $year, month => $month, day => $day );
                    $start_date = $start->ymd;
                }
                else {
                    warn('Period not recognized: ' . $period);
                    next;
                }

                my $requests_data = {
                    start_date     => $start_date,
                    type           => $metric,
                    counter_title  => $journal_rec->id,
                    counter_source => $source->id,
                };
                
                my @existing_records = CUFTS::DB::ERMCounterCounts->search($requests_data);
                foreach my $record (@existing_records) {
                    if ( $DEBUG ) {
                        warn('Deleting existing count record id: ' . $record->id . "\n" );
                    }
                    $record->delete();
                }
                $requests_data->{count} = $num;
                my $count_rec = CUFTS::DB::ERMCounterCounts->create($requests_data);
            }
        }

       CUFTS::DB::DBI->dbi_commit();
        # CUFTS::DB::DBI->dbi_rollback();

    }
    
}

# $report should be a Biblio::COUNTER report
sub load_report_db1 {
    my ( $source, $report ) = @_;
    
    if ( $DEBUG ) {
        warn("Publisher: "  . $report->publisher    . "\n");
        warn("Platform: "   . $report->platform     . "\n");
        warn("Date: "       . $report->date_run     . "\n");
    }
    
    my $periods = $report->periods;
    foreach my $database ( $report->records ) {

        my $title = $database->{title};
        $title = decode_entities(decode_entities($title)); # Necessary for Scholarly Stats, at least - decode &amp; in XML, then decode the result to real characters
        next if is_empty_string($title);

    
        # Clean up quotes around title
    
        $title = trim_string($title, '"');
    
        my $database_data = {
            title  => $title,
        };
        
        if ( $DEBUG ) {
            warn(Dumper($database_data) . "\n");
        }
        
        # Find or create a new COUNTER titles record
        my $database_rec = CUFTS::DB::ERMCounterTitles->search($database_data)->first;
        if ( !$database_rec ) {
            $database_rec = CUFTS::DB::ERMCounterTitles->create($database_data);
        }
        
        # Loop through the counts and create a COUNTER counts record for each reported period for this database
        
        my $count  = $database->{count};
        foreach my $period ( keys %$count ) {
            while ( my ($metric, $num) = each %{ $count->{$period} } ) {
                if ( $DEBUG ) {
                    warn("* $metric: $num\n");
                }

                # Get the start date from the period which comes out as just YYYY-MM from Biblio::COUNTER

                my $start_date;
                if ( $period =~ /^(\d{4})-(\d{2})$/ ) {
                    my ( $year, $month, $day ) = ( $1, $2, 1 );
                    my $start = DateTime->new( year => $year, month => $month, day => $day );
                    $start_date = $start->ymd;
                }
                else {
                    warn('Period not recognized: ' . $period);
                    next;
                }
                
                my $requests_data = {
                    start_date     => $start_date,
                    type           => $metric,
                    counter_title  => $database_rec->id,
                    counter_source => $source->id,
                };
                
                my @existing_records = CUFTS::DB::ERMCounterCounts->search($requests_data);
                foreach my $record (@existing_records) {
                    if ( $DEBUG ) {
                        warn('Deleting existing count record id: ' . $record->id . "\n" );
                    }
                    $record->delete();
                }
                $requests_data->{count} = $num;
                my $count_rec = CUFTS::DB::ERMCounterCounts->create($requests_data);
            }
        }

       CUFTS::DB::DBI->dbi_commit();
        # CUFTS::DB::DBI->dbi_rollback();

   }
    
}




1;
