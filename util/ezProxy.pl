#!/usr/local/bin/perl

use lib qw(lib);

$| = 1;

my $PROGRESS = 1;

use strict;

use Data::Dumper;

use CUFTS::Config;
use CUFTS::Util::Simple;

use URI;

my $schema = CUFTS::Config::get_schema();

my $journals_rs = $schema->resultset('CJDBJournals')->search({ site => 1 });

my %hosts;
my $count = 0;

while ( my $journal = $journals_rs->next ) {
#    last if $count++ == 1000;

    foreach my $link ( $journal->links->all ) {
        my $url = $link->url;

        # Skip already proxied
        next if $url !~ s{^http://proxy\.lib\.sfu\.ca/login\?url=}{};

        # Add "http://" if it's not there
        if ($url !~ /^https?:/) {
            $url = "http://${url}";
        }

        my $uri  = URI->new($url);
        my $host = $uri->host;

        $hosts{$host}++;

    }
}

foreach my $host ( keys %hosts ) {
    print "T ${host}\n";
    print "U http://${host}/\n";
    print "U https://${host}/\n";
    print "HJ ${host}\n";

    if ( $host =~ / ( [^\.]+ \. [^\.]+ ) $/xsm ) {
        print "DJ $1\n\n";
    } else {
        warn( "Could not determine domain for host: $host" );
    }

}