
use lib qw(lib);

use strict;

use CUFTS::Exceptions;
use CUFTS::Config;
use CUFTS::CJDB::Util;

use CUFTS::Util::Simple;
use Getopt::Long;

my %options;
GetOptions( \%options, 'site_key=s', 'site_id=i', 'cjdb_key=s', 'cjdb_id=i' );
my @files = @ARGV;

my $schema = CUFTS::Config::get_schema();

##
## Load the site
##

my $site;
if ( $options{site_id} ) {
    $site = $schema->resultset('Sites')->find({ id => int($options{site_id}) });
}
elsif ( $options{site_key} ) {
    $site = $schema->resultset('Sites')->find({ key => $options{site_key} });
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
    $account = $sites->cjdb_accounts({ id => int($options{cjdb_id}) })->first();
}
elsif ( $options{cjdb_key} ) {
    $account = $sites->cjdb_accounts({ key => $options{cjdb_key} })->first();
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

        my @issns = $schema->resultset('CJDBISSNs')->search({ site => $site_id, issn => $row }, { prefetch => ['journal'] });
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
            $schema->resultset('CJDBTags')->find_or_create( $record );
        }
    }
    else {
        $tag = lc($row);
        print "Found new tag: $tag\n";
        next;
    }

}

close TAGFILE;
