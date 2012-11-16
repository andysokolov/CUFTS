
use lib qw(lib);

use strict;

use CUFTS::Exceptions;
use CUFTS::Config;

use CUFTS::DB::Resources;
use CUFTS::DB::ERMCounterSources;
use CUFTS::COUNTER;

use CUFTS::Util::Simple;
use Getopt::Long;

my %options;
GetOptions( \%options, 'source_id=i' );
my @files = @ARGV;

##
## Load the site
##

my $source;
if ( $options{source_id} ) {
    $source = CUFTS::DB::ERMCounterSources->search({ id => int($options{source_id}) })->first();
}
if ( !$source ) {
    die("Unable to load ERM COUNTER source or key/id was not passed in.\n");
}

##
## Only deal with one file for now.
##

open COUNTER, $files[0] or
    die("Unable to open $files[0]: $!");

CUFTS::COUNTER::load_report( $source, \*COUNTER );

close TAGFILE;