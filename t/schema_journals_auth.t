use strict;
use warnings;

use Test::More tests => 14;

use Test::DBIx::Class {
    schema_class => 'CUFTS::Schema',
    connect_info => ['dbi:Pg:dbname=CUFTStesting','CUFTStesting',''],
    force_drop_table  => 1,
    fail_on_schema_break => 1,
};

my $schema = Schema;
my $timestamp = $schema->get_now();
like($timestamp, qr/^[-\d]+\s[-\.:\d]+$/, 'timestamp as extra check that TestDatabase loaded');

# Setup basic testing data

$schema->resultset('JournalsAuth')->create({
	title => 'Journal of First Test',
	titles => [ { title => 'Journal of First Test', title_count => 1 }, { title => 'Journal of First Test Society', title_count => 2 } ],
	issns  => [ { issn => '11112222' }, { issn => '2222-555x' } ],
});

$schema->resultset('JournalsAuth')->create({
	title => 'Journal of Second Test',
	titles => [ { title => 'Journal of Second Test', title_count => 15 }, { title => 'Second Journal of Testing', title_count => 12 } ],
	issns  => [ { issn => '56564421' } ],
});

$schema->resultset('JournalsAuth')->create({
	title => 'Journal of Third Test',
	titles => [ { title => 'Journal of Third Test', title_count => 5 }, { title => 'Another Test Journal', title_count => 3 } ],
	issns  => [],
});

$schema->resultset('JournalsAuth')->create({
	title => 'Journal of Fourth Test',
	titles => [ { title => 'Journal of Fourth Test', title_count => 6 }, { title => 'Another Test Journal', title_count => 2 } ],
	issns  => [],
});

$schema->resultset('JournalsAuth')->create({
	title => 'Journal of Fifth Test',
	titles => [ { title => 'Journal of Fifth Test', title_count => 16 } ],
	issns  => [ { issn => '5656-4421' } ],
});

# Make sure the various search shortcuts in the ResultSet are returning expected results

my $r1 = $schema->resultset('JournalsAuth')->find({ title => { 'ilike' => 'journal of first test' } });

is($r1->title, 'Journal of First Test');
my @issns = sort map { $_->issn } $r1->issns;
is_deeply( \@issns, [ '11112222', '2222555X' ], 'issns cleaned and loaded' );

my $rs = $schema->resultset('JournalsAuth')->search_by_issns('11112222', '2222-555x');
isa_ok( $rs, 'CUFTS::ResultSet::JournalsAuth' );
is( $rs->count, 1, 'search_by_issns count check distinct');
is( $rs->first->title, 'Journal of First Test', 'search_by_issns correct distinct record');

$rs = $schema->resultset('JournalsAuth')->search_by_issns( '99999999', '5656-4421' );
is( $rs->count, 2, 'search_by_issns count multiple results');

$rs = $schema->resultset('JournalsAuth')->search_by_exact_title_with_no_issns('Another Test Journal');
is( $rs->count, 0, 'search_by_exact_title_with_no_issns no results');

$rs = $schema->resultset('JournalsAuth')->search_by_exact_title_with_no_issns('Journal of Second Test');
is( $rs->count, 0, 'search_by_exact_title_with_no_issns no results because of issn');

$rs = $schema->resultset('JournalsAuth')->search_by_exact_title_with_no_issns('Journal of Third Test');
is( $rs->count, 1, 'search_by_exact_title_with_no_issns single result');
is( $rs->first->title, 'Journal of Third Test', 'search_by_issns correct distinct record');

$rs = $schema->resultset('JournalsAuth')->search_by_title_with_no_issns('Another Test Journal');
is( $rs->count, 2, 'search_by_title_with_no_issns two results');

$rs = $schema->resultset('JournalsAuth')->search_by_exact_title_with_no_issns('Journal of First Test Society');
is( $rs->count, 0, 'search_by_title_with_no_issns no results because of issn');

# Test a way of doing "find_or_create" against a resultset that already includes a search.

$r1->issns->find_or_create({ issn => '1111-2222' });
$r1->issns->find_or_create({ issn => '9111-1119' });
@issns = sort map { $_->issn } $r1->issns;

is_deeply( \@issns, [ '11112222', '2222555X', '91111119' ], 'find_or_create() with issns' );

1;
