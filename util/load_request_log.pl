#!/usr/local/bin/perl

use lib 'lib';
use strict;

use CUFTS::DB::Stats;
use CUFTS::DB::Sites;

use Data::Dumper;

my @request_fields = qw(
    timestamp
    site
    
    genre
    issn
    eissn
    title
    atitle
    volume
    issue
    spage
    epage
    pages
    date
    doi

    aulast
    aufirst
    auinit
    auinit1
    auinitm

    artnum
    part
    coden
    isbn
    sici
    bici
    stitle

    ssn
    quarter

    oai
    pmid
    bibcode

    id
    sid
);


# Build site map

my %site_map;
my @sites = CUFTS::DB::Sites->retrieve_all;
foreach my $site ( @sites ) {
    $site_map{ $site->key } = $site->id;
}

while (<>) {
    my @fields = split "\t", $_;
    my %request = map { $_, shift @fields } @request_fields;
    
    my ( $date, $time ) = split ' ', $request{timestamp};
    
    next unless int($date) > 20070201;
    next unless int($date) < 20080105;
    
    my $db_log = {
        'request_date' => $date,
        'request_time' => $time,
        'site' => $site_map{$request{site}},
        'issn' => ( defined( $request{issn} ) 
                    ? $request{issn}
                    : $request{eissn}
        ),
        'isbn'  => $request{isbn},
        'title' => ( defined( $request{title} ) 
                     ? $request{title}
                     : $request{stitle}
        ),
        'volume'  => $request{volume},
        'issue'   => $request{issue},
        'date'    => $request{date},
        'doi'     => $request{doi},
        'results' => ( scalar(@fields) > 0 ? 't' : 'f' ),
    };
    print '.';
    
    # print Dumper($db_log), "\n";
    CUFTS::DB::Stats->create( $db_log );
}

CUFTS::DB::DBI->dbi_commit;

