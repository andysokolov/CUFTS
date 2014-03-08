#!/usr/local/bin/perl

##
## Creates a CSV of journal holdings for the Browzine service
##

use strict;
use lib qw(lib);

use Data::Dumper;
use Term::ReadLine;
use Getopt::Long;
use IO::File;
use String::Util qw(hascontent);

use CUFTS::Config;
use CUFTS::Schema;
use CUFTS::Util::Simple;

my $schema = CUFTS::Schema->connect( $CUFTS::Config::CUFTS_DB_STRING, $CUFTS::Config::CUFTS_USER, $CUFTS::Config::CUFTS_PASSWORD );
my $term = new Term::ReadLine 'CUFTS Browzine Dump';

$| = 1;

my %options;
GetOptions( \%options, 'site_key=s', 'site_id=i', 'all' );

my $sites_rs;
if ( $options{all} ) {
    $sites_rs = $schema->resultset('Sites');
}
elsif ( $options{site_id} || $options{site_key} ) {
    my $site_search =   $options{site_id}   ? { id => int($options{site_id}) }
                      : $options{site_key}  ? { key => $options{site_key} }
                      : {};

    $sites_rs = $schema->resultset('Sites')->search($site_search);
}
else {
    die('Missing all option or site_key/id.');
}


while ( my $site = $sites_rs->next ) {
    print "Checking " . $site->name . "\n";
    load_site($site);
	print "Finished ", $site->name,  "\n";
}

print "Done!\n";



sub load_site {
    my ($site) = @_;

    my $OUT = get_output_fh($site);

	my $site_id = $site->id;

    my $local_resources_rs = $site->local_resources->search(
        {
            'me.active' => 't',
        },
        {
            prefetch => [ 'resource' ],
        }
    );

    print $OUT join "\t", ( 'source', 'title', 'issn1', 'issn2', 'start', 'end', 'embargo_days', 'embargo_months' );
    print $OUT "\n";

    while ( my $local_resource = $local_resources_rs->next ) {
        print " - Loading: ", $local_resource->name_display, ": ";

        # Prefetch the most common data linkage - journal and journal_auth linked from there.
        my $local_journals_rs = $local_resource->local_journals({},
            {
                prefetch => { 'global_journal' => 'journal_auth' },
            }
        );

        my $count = 0;
        while ( my $local_journal = $local_journals_rs->next ) {

            my $journal_auth = $local_journal->journal_auth_merged;
            next if !defined($journal_auth);

            my $issns = $journal_auth->issns_display;
            next if !scalar(@$issns);

            my $start = $local_journal->ft_start_date_merged;
            my $end   = $local_journal->ft_end_date_merged;

            next if !hascontent($start) && !hascontent($end);

            $count++;
            my @row = ( $local_resource->name_display, 
                        $journal_auth->title, 
                        $issns->[0], 
                        exists($issns->[1]) ? $issns->[1] : undef,
                        defined($start) ? $start->ymd : undef,
                        defined($end)   ? $end->ymd   : undef,
                        $local_journal->embargo_days_merged,
                        $local_journal->embargo_months_merged,
            );

            print $OUT join "\t", @row;
            print $OUT "\n";

        }
        print $count, "\n";

    }

    close $OUT;
    return;
}




sub get_output_fh {
    my ($site) = @_;

    if ( !defined($site) ) {
        die("No site defined in output()");
    }

    my $dir = $CUFTS::Config::CUFTS_RESOLVER_SITE_DIR;

    # First run - create directories if necessary, delete any
    # existing files.

    -d $dir
        or die("No directory for the CUFTS resolver site files: $dir");

    $dir .= '/' . $site->id;
    -d $dir
        or mkdir $dir
            or die("Unable to create directory $dir: $!");

    $dir .= '/static';
    -d $dir
        or mkdir $dir
            or die("Unable to create directory $dir: $!");

    $dir .= '/Browzine';
    -d $dir
        or mkdir $dir
            or die("Unable to create directory $dir: $!");

    opendir BZDIR, $dir
        or die("Unable to open GS dir: $!");

    # Delete all files in Browzine directory that do not start with '.'

    my @unlink_files = map { "$dir/$_" } grep !/^\./, readdir BZDIR;
    closedir BZDIR;
    my @unlink_errs = grep {not unlink} @unlink_files;
    if (@unlink_errs) {
        die("Unable to remove exising Browzine files: @unlink_errs\n")
    }

    my $file = "$dir/browzine_" . $site->key . ".txt";

    my $fh = new IO::File(">$file")
        or die("Unable to open file ($file) for writing: $!");

    return $fh;
}
