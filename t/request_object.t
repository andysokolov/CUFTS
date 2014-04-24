use strict;

use Test::More tests => 41;

BEGIN {
	use_ok('CUFTS::Request');
}

# Internal cleanup testing.

my $r1 = CUFTS::Request->new();
isa_ok($r1, 'CUFTS::Request');

is( $r1->genre, 'article', 'article genre default' );

$r1->issn('1234-567x');
is( $r1->issn, '1234567X', 'issn cleanup');

$r1->eissn('2234-567x');
is( $r1->eissn, '2234567X', 'eissn cleanup');

$r1->other_issns([]);
is_deeply( $r1->other_issns, [], 'other_issn empty');

$r1->other_issns([ '11112222' ]);
is_deeply( $r1->other_issns, [ '11112222' ], 'other_issn valid');

$r1->other_issns([ '2222-333x', '3333-4444' ]);
is_deeply( $r1->other_issns, [ '2222333X', '33334444' ], 'other_issn cleanup' );

is_deeply( [ $r1->issns ], [ '1234567X', '2234567X', '2222333X', '33334444' ], 'issns list' );

$r1->spage('1');
is($r1->spage, '1', 'spage setting');

$r1->epage('100');
is($r1->epage, '100', 'epage setting');

$r1->pages('5-50');
is($r1->spage, '1', 'spage still set');
is($r1->epage, '100', 'epage still set');
is($r1->pages, '5-50', 'pages setting');

my $r2 = CUFTS::Request->new();
isa_ok($r2, 'CUFTS::Request');

$r2->pages('25-55');
is($r2->pages, '25-55', 'pages setting');
is($r2->spage, '25', 'spage from pages');
is($r2->epage, '55', 'epage from pages');

my $r3 = CUFTS::Request->new();
isa_ok($r3, 'CUFTS::Request');

$r3->date('2012-04-20');
is($r3->date, '2012-04-20', 'date set');
is($r3->year,  '2012',      'year from date');
is($r3->month, '04',        'month from date');
is($r3->day,   '20',        'day from date');

my $r4 = CUFTS::Request->parse_openurl_0({
	genre  => 'article',
	issn   => '0378-5173',
	sici   => '0378-5173(20130130)441:1/2<121:IJOP85154062>2.0.TX;2-9',
	title  => 'International Journal of Pharmaceutics',
	atitle => 'Bitterness prediction of H1-antihistamines and prediction of masking effects of artificial sweeteners using an electronic tongue.',
	volume => '441',
	issue  => '12',
	spage  => '121',
	date   => '2013-01-30',
});
isa_ok($r4, 'CUFTS::Request');

is($r4->issn, 	'03785173', 'openurl0: issn');
is($r4->sici, 	'0378-5173(20130130)441:1/2<121:IJOP85154062>2.0.TX;2-9', 'openurl0: sici');
is($r4->title, 	'International Journal of Pharmaceutics', 'openurl0: title');
is($r4->atitle, 'Bitterness prediction of H1-antihistamines and prediction of masking effects of artificial sweeteners using an electronic tongue.', 'openurl0: atitle');
is($r4->volume, '441', 'openurl0: volume');
is($r4->issue, 	'12', 'openurl0: issue');
is($r4->spage, 	'121', 'openurl0: spage');
is($r4->date, 	'2013-01-30', 'openurl0: date');


my $r5 = CUFTS::Request->parse_openurl_1({
	'ctx_ver'           => 'Z39.88-2004',
	'ctx_enc'           => 'info:ofi/enc:UTF-8',
	'rfr_id'            => 'info:sid/summon.serialssolutions.com',
	'rft_val_fmt'       => 'info:ofi/fmt:kev:mtx:journal',
	'rft.genre'         => 'article',
	'rft.atitle'        => 'Social studies: World War II Japanese-American internment camps',
	'rft.jtitle'        => 'School Library Media Activities Monthly',
	'rft.au'            => [ 'Henley, Susan', 'Thompson, Helen' ],
	'rft.date'          => '1997-04-01',
	'rft.pub'           => 'Libraries Unlimited, Inc',
	'rft.issn'          => '0889-9371',
	'rft.volume'        => '13',
	'rft.issue'         => '8',
	'rft.spage'         => '23',
});
isa_ok($r5, 'CUFTS::Request');

is($r5->issn, 	'08899371', 'openurl1: issn');
is($r5->title, 	'School Library Media Activities Monthly', 'openurl1: title');
is($r5->atitle, 'Social studies: World War II Japanese-American internment camps', 'openurl1: atitle');
is($r5->volume, '13', 'openurl1: volume');
is($r5->issue, 	'8', 'openurl1: issue');
is($r5->spage, 	'23', 'openurl1: spage');
is($r5->date, 	'1997-04-01', 'openurl1: date');

my $r6 = CUFTS::Request->parse_openurl_0({
	genre  => 'article',
	issn   => '0378-5173',
	volume => '441',
	issue  => '12',
	title  => '',
	spage  => '121',
	date   => '2013-01-30',
});
isa_ok($r6, 'CUFTS::Request');
