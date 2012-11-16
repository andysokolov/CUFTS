
use lib qw(lib);

use strict;

use CUFTS::Exceptions;
use CUFTS::Config;
use CUFTS::CJDB::Util;

use CUFTS::DB::Resources;
use CJDB::DB::Journals;
use CJDB::DB::ISSNs;
use CJDB::DB::Tags;

use CUFTS::Util::Simple;
use Getopt::Long;

my %options;
GetOptions( \%options, 'site_key=s', 'site_id=i', 'cjdb_key=s', 'cjdb_id=i' );
my @files = @ARGV;

##
## Load the site
##

my $site;
if ( $options{site_id} ) {
    $site = CUFTS::DB::Sites->search({ id => int($options{site_id}) })->first();
}
elsif ( $options{site_key} ) {
    $site = CUFTS::DB::Sites->search({ key => $options{site_key} })->first();
}
if ( !$site ) {
    die("Unable to load site or site key/id was not passed in.");
}
my $site_id = $site->id;

##
## Get the CJDB account to attach tags to
##

my $account;
if ( $options{cjdb_id} ) {
    $account = CJDB::DB::Accounts->search({ id => int($options{cjdb_id}), site => $site_id })->first();
}
elsif ( $options{cjdb_key} ) {
    $account = CJDB::DB::Accounts->search({ key => $options{cjdb_key}, site => $site_id })->first();
}
if ( !$account ) {
    die("Unable to load cjdb account record or cjdb key/id was not passed in.");
}
my $account_id = $account->id;

##
## Only deal with one file for now.
##

open TAGFILE, $files[0] or
    die("Unable to open $files[0]: $!");

local CJDB::DB::DBI->db_Main->{ AutoCommit };

my $tag = '';
while ( my $row = <TAGFILE> ) {

    chomp($row);
    $row = trim_string($row);
    next if is_empty_string($row);

    if ( $row =~ /^(\d{4})\-?(\d{3}[\dxX])$/ ) {
        
        $row = uc("$1$2");
        if ( is_empty_string($tag) ) {
            die("Attempting to process ISSN ($row) before a tag has been defined\n");
        }
        
        # Find a matching journal based on ISSN
        
        my @issns = CJDB::DB::ISSNs->search( { site => $site_id, issn => $row }, { prefetch => ['journal'] } );
        if ( scalar(@issns) == 0 ) {
            print("No matching records found for ISSN: $row\n");
            next;
        }
        
        # Add a tag to each journal found

        foreach my $issn ( @issns ) {
            my $journal = $issn->journal;
            my $record = {
                tag           => $tag,
                account       => $account_id,
                site          => $site_id,
                level         => 100,
                viewing       => 1,
                journals_auth => $journal->journals_auth,
            };
            CJDB::DB::Tags->find_or_create( $record );
        }
    }
    else {
        $tag = lc($row);
        print "Found new tag: $tag\n";
        next;
    }
    
}

#CJDB::DB::DBI->dbi_rollback();
CJDB::DB::DBI->dbi_commit();

close TAGFILE;