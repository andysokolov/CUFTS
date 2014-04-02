use strict;
use warnings;

use Test::More tests => 22;

use Test::DBIx::Class {
    schema_class => 'CUFTS::Schema',
    connect_info => ['dbi:Pg:dbname=CUFTStesting','CUFTStesting','', { quote_names => 1 }],
    force_drop_table  => 1,
    fail_on_schema_break => 1,
};

use FindBin;
my $test_file_dir = "$FindBin::Bin/data";

use_ok('CUFTS::COUNTER');

my $schema = Schema;
my $timestamp = $schema->get_now();
like($timestamp, qr/^[-\d]+\s[-\.:\d]+$/, 'timestamp as extra check that TestDatabase loaded');

# Setup basic testing data

my $site = $schema->resultset('Sites')->create({
    name         => 'Test University',
    active       => 'true',
    proxy_prefix => 'PROXY:',
});

my $sushi1 = $schema->resultset('ERMSushi')->create({
    site 	=> $site->id,
    name => 'Test SUSHI 1',
});

my $counter1 = $schema->resultset('ERMCounterSources')->create({
    site      => $site->id,
    type      => 'j',
    name      => 'Test COUNTER Nature',
    erm_sushi => $sushi1->id,
});

my $counter2 = $schema->resultset('ERMCounterSources')->create({
    site      => $site->id,
    type      => 'j',
    name      => 'Test COUNTER EBSCO',
    erm_sushi => $sushi1->id,
});

my $counter3 = $schema->resultset('ERMCounterSources')->create({
    site      => $site->id,
    type      => 'j',
    name      => 'Test COUNTER ACS',
    erm_sushi => $sushi1->id,
});

ok( defined $sushi1,   'SUSHI record created' );
ok( $sushi1->id > 0,   'SUSHI record has created id');
ok( defined $counter1, 'COUNTER record created' );
ok( $counter1->id > 0, 'COUNTER record has created id');


# Test a few COUNTER JR1 (R4) lists

open( my $nature_test_file, "<", "$test_file_dir/COUNTER_JR1_R4_Nature.txt" ) or die("Unable to open test file COUNTER_JR1_R4_Nature.txt: $!");

CUFTS::COUNTER::load_report( $counter1, $nature_test_file );

is( $schema->resultset('ERMCounterCounts')->count, 1008, 'loaded 1008 records for Nature' );

my $title1 = $schema->resultset('ERMCounterTitles')->search({ title => 'Nature Physics' })->first;
ok( defined $title1, 'loaded and found title: Nature Physics' );

is( $counter1->counts({ counter_title => $title1->id })->count, 12, 'title1: loaded row' );
is( $counter1->counts({ counter_title => $title1->id, start_date => '2013-12-01' })->first->count, 115, 'individual count for found title' );

open( my $ebsco_test_file, "<", "$test_file_dir/COUNTER_JR1_R4_EBSCO.txt" ) or die("Unable to open test file COUNTER_JR1_R4_EBSCO.txt: $!");
CUFTS::COUNTER::load_report( $counter2, $ebsco_test_file );

is( $schema->resultset('ERMCounterCounts')->count, 16236, 'loaded 15228 records for EBSCO' );

my $title2 = $schema->resultset('ERMCounterTitles')->search({ title => 'Academicus' })->first;
ok( defined $title2, 'loaded and found a title: Academicus' );

is( $counter2->counts({ counter_title => $title2->id })->count, 12, 'title2: loaded row' );
is( $counter2->counts({ counter_title => $title2->id, start_date => '2013-10-01' })->first->count, 34, 'individual count for found title' );

# This one includes some duplicate titles from the above list
open( my $acs_test_file, "<", "$test_file_dir/COUNTER_JR1_R4_ACS.txt" ) or die("Unable to open test file COUNTER_JR1_R4_ACS.txt: $!");
CUFTS::COUNTER::load_report( $counter3, $acs_test_file );

my $title3 = $schema->resultset('ERMCounterTitles')->search({ title => 'Academic Questions', 'issn' => '08954852' })->first;
ok( defined $title3, 'loaded and found a title: Academic Questions' );

is( $title3->counts->count, 24, 'title3: loaded multiple rows to same title record' );
is( $counter3->counts({ counter_title => $title3->id })->count, 12, 'title3: loaded new row' );
is( $counter2->counts({ counter_title => $title3->id })->count, 12, 'title3: old row exists' );

my $title4 = $schema->resultset('ERMCounterTitles')->find({ doi => '10.1038/tpj' });
ok( defined $title4, 'loaded and found a title by doi: 10.1038/tpj' );

is( $title4->counts->count, 24, 'title4: loaded multiple rows to same title record' );
is( $counter3->counts({ counter_title => $title4->id })->count, 12, 'title4: loaded new row' );
is( $counter1->counts({ counter_title => $title4->id })->count, 12, 'title4: old row exists' );




1;
