#!/usr/local/bin/perl -w

##
## Change the line above if your perl is located elsewhere.
##

$| = 1;

use strict;
use lib qw(lib);

use CUFTS::Config;
use CUFTS::DB::LocalJournals;
use CUFTS::DB::LocalResources;
use CUFTS::DB::JournalsAuth;

use Data::Dumper;
use ZOOM;

my $HOST      = 'z3950.loc.gov';
my $PORT      = 7090;
my $DATABASE  = 'voyager';
my $marc_file = '/tmp/locMarc.mrc';

##--------------------------------------------------------------------

# Empty the marc file
open (my $fh, ">", $marc_file) || die "Can't open file: $!";

my $conn = new ZOOM::Connection($HOST, $PORT, databaseName => $DATABASE)
           or die "can't connect: $!";
print "Connected to and querying $HOST\n";

my $count = 0;
my $j = 1;

my $journal_auths = CUFTS::DB::JournalsAuth->search({ marc => undef });
while ( my $journal_auth = $journal_auths->next ) {
    foreach my $issn ( $journal_auth->issns ) {

        my $search = '@attr 1=8 @attr 3=1 @attr 5=1 "' . $issn->issn_dash . '"';

        # Try and catch perl style
        eval {
            my $rs = $conn->search_pqf($search) or die $conn->errmsg();
            $rs->option(preferredRecordSyntax => 'usmarc');

            #print $rs->size() . " found for " . $search . "\n";
            for (my $i = 0; $i < $rs->size(); $i++) {
                if ( my $rec = $rs->record($i) ) {
                    # Write MARC to the file
                    print $fh $rec->raw();
                    $count++;
                }
                else {
                    warn "Record ", $i+1, ": error #", $rs->errcode(), " (", $rs->errmsg(), "): ", $rs->addinfo(), "\n";
                    warn "Search was: " . $search . "\n";
                }
            }
        };
        
        if ($@) {
            print "Closing the connection due to $@ \n";
            $conn = reopen($conn);
        }
    }

    $j++;
    print "Processed $j journal_auth records\n" if $j % 100 == 0;
    $conn = reopen($conn) if $j % 500 == 0;

}   
close($fh);

print "Wrote " . $count  . " MARC files to " . $marc_file . "\n";
print "You'll probably want to run: \n";
print "perl util/journal_auth_marc_update.pl " . $marc_file . "\n";
$conn->destroy();

sub reopen {
    my $conn = shift;
    $conn->destroy();
    print "Sleeping for 2 minutes.\n";
    sleep(120);
    my $new_conn = new ZOOM::Connection($HOST, $PORT, databaseName => $DATABASE) 
        or die "Can't connect: $!";
    print "Connection reopened.\n";
    return $new_conn;
}