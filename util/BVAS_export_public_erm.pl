#!/usr/local/bin/perl

use strict;

use lib qw(lib);

use DateTime;
use CUFTS::Config;

my $url_base = 'http://cufts2.lib.sfu.ca/CRDB4/BVAS/resource/';

my $rs = CUFTS::Config->get_schema->resultset('ERMMain')->search({ site => 1, public_list => 'yes' });

my $filename = '/tmp/erm_public_' . DateTime->now->ymd . '.mrc';

open( my $fh, ">", $filename ) or die "Unable to open $filename: $!";

while ( my $erm_main = $rs->next ) {
    print $fh $erm_main->as_marc( $url_base )->as_usmarc();
}

close($fh);