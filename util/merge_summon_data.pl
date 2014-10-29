#!/usr/local/bin/perl

##
## This script checks all CUFTS sites for files that are
## marked for reloading and then loads the print/CUFTS records
## if required.
##


$| = 1;

use Data::Dumper;

use lib qw(lib);

use CUFTS::Config;
use CUFTS::Request;
use CUFTS::Resolve;

use String::Util qw(hascontent trim);
use IO::File;
use Text::CSV_XS;
use Getopt::Long;
use Log::Log4perl qw(:easy);
use Unicode::String qw(utf16 utf8 latin1);

use strict;

my %options;
GetOptions( \%options, 'site_key=s', 'site_id=i' );

my $schema = CUFTS::Config::get_schema();

Log::Log4perl->easy_init($INFO);
my $logger = Log::Log4perl->get_logger();

my $site;
if ( $options{site_id} ) {
    $site = $schema->resultset('Sites')->find({ id => $options{site_id} });
}
elsif ( $options{site_key} ) {
    $site = $schema->resultset('Sites')->find({ key => $options{site_key} });
}
else {
    usage();
    exit;
}

if ( !scalar @ARGV ) {
    usage();
    exit;
}

if ( !defined $site ) {
    die("Unable to load site.");
}

my %records_by_dbcode;
my $csv_in = Text::CSV_XS->new({ sep_char => "\t", eol => "\n", empty_is_undef => 1, });

FILE:
foreach my $filename ( @ARGV ) {
    $logger->info("Opening: $filename");
    open my $in_fh, "<:encoding(utf16)", $filename or die "$filename: $!";

    my ($db_code) = $filename =~ m{/(...)_};
    if ( !hascontent($db_code) ) {
        $logger->warn("Unable to extract db_code from filename: $filename");
        next FILE;
    }
    my $resource = get_resource_from_db_code($schema, $db_code, $site);
    if ( !defined $resource ) {
        $logger->warn("Unable to find matching resource for $db_code");
        next FILE;
    }
    $logger->info("Loaded resource: " . $resource->name);

    open my $out_fh, ">", "$filename.processed";
    while ( my $row = $csv_in->getline($in_fh) ) {
        if ( $row->[0] !~ /\(\*/ ) {
            $csv_in->column_names($row);
            last;
        }
    }

    print $out_fh join("\t", $csv_in->column_names), "\n";

    my $count = 0;
    while ( my $row = $csv_in->getline_hr($in_fh) ) {

        $row->{Status} = 'Not Tracked';

        if ( $row->{Type} eq 'Journal' ) {

            my $records = get_cufts_records($schema, $resource, $site, $row);
            if ( scalar @$records ) {
                $logger->info("Matched: ", join(', ', $row->{Title}, $row->{'ISSN/ISBN'}, $row->{'Default Dates'}) );
                foreach my $record (@$records) {
                    $logger->info("With:    ", join(', ', $record->title, $record->issn, $record->e_issn, (defined $record->ft_start_date ? $record->ft_start_date->ymd : ''), (defined $record->ft_end_date ? $record->ft_end_date->ymd : '') ) );
                }
                $row->{Status} = 'Tracked';
                $count++;

                if ( scalar @$records == 1 ) {
                    my $record = $records->[0];
                    if ( defined $record->ft_start_date ) {
                        $row->{'Custom Date From'} = $record->ft_start_date;
                    }
                    if ( defined $record->ft_end_date ) {
                        $row->{'Custom Date To'} = $record->ft_end_date;
                    }
                }
                elsif ( scalar @$records > 1 ) {
                    $logger->warn('Matched multiple records for ' . $row->title);
                }
            }

        }

        print $out_fh row_string($csv_in, $row);

    }

    close $in_fh;
    close $out_fh;

    $logger->info("Finished processing. Found $count journals tracked.");
}


foreach my $key ( keys %records_by_dbcode ) {
    print "$key: ", scalar @{ $records_by_dbcode{$key} }, "\n";
}

sub row_string {
    my ( $csv, $row ) = @_;
    return join("\t", map { $row->{$_} } $csv->column_names) . "\n";
}


sub get_resource_from_db_code {
    my ( $schema, $db_code, $site ) = @_;

    if ( $db_code eq 'RIG' ) {
        my $local_resource = $schema->resultset('LocalResources')->find({ id => 1759 });
        if ( defined $local_resource ) {
            return CUFTS::Resolve->overlay_global_resource_data($local_resource);
        }
    }
    return undef;
}

sub get_cufts_records {
    my ( $schema, $resource, $site, $row ) = @_;

    my $request = CUFTS::Request->new({ title  => $row->{Title} });
    if ( hascontent($row->{'ISSN/ISBN'}) && $row->{'ISSN/ISBN'} =~ /^\d{4}-?\d{3}[\dxX]$/ ) {
        $request->issn( uc($row->{'ISSN/ISBN'}) );
    }
    # if ( hascontent($row->{eISSN}) && $row->{eISSN} =~ /\d{4}-?\d{3}\d[xX]/ ) {
    #     $request->e_issn( uc($row->{eISSN}) );
    # }

    return undef if !defined $resource->module;
    my $module = CUFTS::Resolve::__module_name( $resource->module );
    return undef if !$module->can('get_records');
    my $records = $module->get_records( $schema, $resource, $site, $request );

    return $records;
}

# sub load_site {
#     my ($site) = @_;

#     my $fh = new IO::File "> /tmp/summon.txt";
#     if ( !defined($fh) ) {
#         die( "Unable to create file for output.\n" );
#     }

#     my $site_id = $site->id;

#     my $lj_iter = CUFTS::DB::LocalJournals->search({
#         'active'          => 't',
#         'resource.active' => 't',
#         'resource.site'   => $site_id,
#     },
#     );
#     my %jas;
#     my $count;
#     while ( my $lj = $lj_iter->next ) {

#         my $gj = $lj->journal;
#         my $ft_start_date  = defined($lj->ft_start_date)  ? $lj->ft_start_date  : defined($gj) ? $gj->ft_start_date  : undef;
#         my $ft_end_date    = defined($lj->ft_end_date)    ? $lj->ft_end_date    : defined($gj) ? $gj->ft_end_date    : undef;
#         my $embargo_days   = defined($lj->embargo_days)   ? $lj->embargo_days   : defined($gj) ? $gj->embargo_days   : undef;
#         my $embargo_months = defined($lj->embargo_months) ? $lj->embargo_months : defined($gj) ? $gj->embargo_months : undef;
#         my $ja_id          = defined($lj->journal_auth)   ? $lj->journal_auth   : defined($gj) ? $gj->journal_auth   : undef;

#         next if !defined($ja_id);

#         next if    is_empty_string($ft_start_date  )
#                 && is_empty_string($ft_end_date    )
#                 && is_empty_string($embargo_days   )
#                 && is_empty_string($embargo_months );

#         if ( !defined($ft_start_date) ) {
#             $jas{$ja_id}->{start} = undef;
#         }
#         elsif ( !defined($jas{$ja_id}->{start}) || $ft_start_date lt $jas{$ja_id}->{start} ) {
#             $jas{$ja_id}->{start} = $ft_start_date;
#         }

#         if ( !defined($ft_end_date) || $ft_end_date eq '2038-12-31' ) {
#             $jas{$ja_id}->{end} = undef;
#         }
#         elsif ( !defined($jas{$ja_id}->{end}) || $ft_end_date gt $jas{$ja_id}->{end} ) {
#             $jas{$ja_id}->{end} = $ft_end_date;
#         }

#         if ( not_empty_string($embargo_months) ) {
#             $embargo_days = $embargo_months * 30;
#         }
#         if ( not_empty_string($embargo_days) ) {
#             if ( !defined($jas{$ja_id}->{embargo}) || $embargo_days < $jas{$ja_id}->{embargo} ) {
#                 $jas{$ja_id}->{embargo} = $embargo_days;
#             }
#         } else {
#             $jas{$ja_id}->{embargo} = 0;
#         }

#     }

#     $csv->print($fh, [
#         "Title (Required)",
#         "Default URL",
#         "Publisher",
#         "Public Note",
#         "Display Public Note",
#         "Location Note",
#         "Display Location Note",
#         "ISSN",
#         "Coverage Date From",
#         "Coverage Date To",
#         "Language ID",
#         "Alphabetization",
#     ]);

#     foreach my $ja_id ( keys %jas ) {
#         my $journal_auth = CUFTS::DB::JournalsAuth->retrieve($ja_id);
#         next if !defined($journal_auth);

#         my $title = $journal_auth->title;

#         my @issns = $journal_auth->issns;
#         my $issn = scalar(@issns) ? $issns[0] : undef;

#         $csv->print( $fh, [
#             $title,
#             "http://cufts2.lib.sfu.ca/CJDB/BVAS/$ja_id",
#             undef,
#             undef,
#             undef,
#             undef,
#             undef,
#             (scalar(@issns) ? $issns[0]->issn : undef),
#             $jas{$ja_id}->{start},
#             $jas{$ja_id}->{end},
#             undef,
#             undef,
#         ]);
#     }


#     $fh->close();

# }


sub usage {
    print <<EOF;

overlay_summon_data summon_file.txt - Takes title lists dumped by Proquest from Summon and overlays it with data from CUFTS.

 site_key=XXX - CUFTS site key (example: BVAS)
 site_id=111  - CUFTS site id (example: 23)

EOF
}
