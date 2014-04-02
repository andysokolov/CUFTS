use strict;
use warnings;

use Test::More tests => 25;

use CUFTS::JournalsAuth;

use Test::DBIx::Class {
    schema_class => 'CUFTS::Schema',
    connect_info => [ 'dbi:Pg:dbname=CUFTStesting','CUFTStesting','', { quote_names => 1 } ],
    force_drop_table  => 1,
    fail_on_schema_break => 1,
};

my $schema = Schema;
my $timestamp = $schema->get_now();
like($timestamp, qr/^[-\d]+\s[-\.:\d]+$/, 'timestamp as extra check that TestDatabase loaded');

# Support records for the next set of created records

my $site = $schema->resultset('Sites')->create({
    name => 'Test University',
    active => 'true',
});

# Create some associated records that should be updated.

my $resource1 = $schema->resultset('GlobalResources')->create({
    name          => 'Test Global Resource 1',
    key           => 'global_resource_1',
    provider      => 'Test Provider',
    module        => 'Test Module',
    resource_type => { type => 'Test Type 1' },
    active        => 't',
});

my $resource2 = $schema->resultset('GlobalResources')->create({
    name          => 'Test Global Resource 2',
    key           => 'global_resource_2',
    provider      => 'Test Provider',
    module        => 'Test Module',
    resource_type => { type => 'Test Type 2' },
    active        => 't',
});


my $journal1 = $resource1->add_to_global_journals({
    title        => 'Journal Title First',
    issn         => '11112222',
});

my $journal2 = $resource1->add_to_global_journals({
    title        => 'Journal Title Second',
    issn         => '22223333',
    e_issn       => '33334444',
});

my $journal3 = $resource2->add_to_global_journals({
    title        => 'Journal Title First',
    issn         => '11112222',
});

my $journal4 = $resource1->add_to_global_journals({
    title        => 'Journal Title Second Alternate',
    issn         => '22223333',
    e_issn       => '33334444',
});

my $local_resource1 = $schema->resultset('LocalResources')->create({
    name          => 'Test Local Resource 1',
    resource_type => { type => 'Test Type 3' },
    site		  => $site->id,
    provider      => 'Test Provider',
    module        => 'Test Module',
    active 		  => 't',
});

my $local_resource2 = $schema->resultset('LocalResources')->create({
    name          => 'Test Local Resource 2',
    resource_type => { type => 'Test Type 4' },
    site		  => $site->id,
    provider      => 'Test Provider',
    module        => 'Test Module',
    active 		  => 't',
});

my $local_journal1 = $local_resource1->add_to_local_journals({
    title        => 'Journal Title Local',
    active       => 't',
});

my $local_journal2 = $local_resource1->add_to_local_journals({
    title        => 'Journal Title Local Two',
    issn         => '11112222',
    active       => 't',
});

my $local_journal3 = $local_resource1->add_to_local_journals({
    title        => 'Journal Title Local Second',
    issn         => '33334444',
    active       => 't',
});


# Quick sanity check

is( $schema->resultset('GlobalResources')->count, 2, 'resources count sanity' );
is( $schema->resultset('LocalResources')->count,  2, 'local resources count sanity' );

is( $schema->resultset('GlobalJournals')->count, 4, 'journals count sanity' );
is( $schema->resultset('LocalJournals')->count,  3, 'local journals count sanity' );

# Create journal_auth records from global journal records

my $stats1 = CUFTS::JournalsAuth::load_journals( $schema, 'global', $timestamp );
warn(ref $stats1);
ok( ref $stats1 eq 'HASH', 'global load: load returned a stats hashref');
is( $schema->resultset('JournalsAuth')->count, 2, 'global load: journal auth count correct' );

my $ja1 = $schema->resultset('JournalsAuth')->find({ title => [ 'Journal Title Second', 'Journal Title Second Alternate' ] });
isnt( $ja1, undef, 'global load: journal auth record found by one of two titles');
is_deeply( [ sort map { $_->issn }  $ja1->issns->all  ], [ '22223333', '33334444' ], 								   'global load: journal auth expected issns' );
is_deeply( [ sort map { $_->title } $ja1->titles->all ], [ 'Journal Title Second', 'Journal Title Second Alternate' ], 'global load: journal auth expected titles' );
is( $ja1->global_journals->count, 2, 'global load: journal auth correct number of linked global journals' );

# Second pass at journals after adding a couple extras that should fail to match properly

my $journal5 = $resource1->add_to_global_journals({
    title        => 'Journal Should Fail',
    issn         => '22223333',
    e_issn       => '9119119X',
});

my $journal6 = $resource1->add_to_global_journals({
    title        => 'Journal Should Also Fail',
    issn         => '22223333',
    e_issn       => '11112222',
});

is( $schema->resultset('GlobalJournals')->count, 6, 'journals count sanity 2' );

my $stats2 = CUFTS::JournalsAuth::load_journals( $schema, 'global', $timestamp );

is( $stats2->{count}, 2, 'global load 2: stats count');
ok( exists $stats2->{multiple_matches} && scalar @{$stats2->{multiple_matches}}, 'global load 2: stats multiple matches error' );
ok( exists $stats2->{too_many_issns}   && scalar @{$stats2->{too_many_issns}},   'global load 2: stats too many issns error' );
ok( exists $stats2->{issn_dupe}        && scalar @{$stats2->{issn_dupe}},        'global load 2: stats issn dupe error' );

$journal5->discard_changes();
$journal6->discard_changes();

is( $journal5->journal_auth, undef, 'global load 2: correct failure to match journal auth: extra ISSN' );
is( $journal6->journal_auth, undef, 'global load 2: correct failure to match journal auth: multiple matches' );

# Create/merge journal_auth records from local journal records

my $stats3 = CUFTS::JournalsAuth::load_journals( $schema, 'local', $timestamp, $site->id );

is( $schema->resultset('JournalsAuth')->count, 3, 'local load: journal auth count correct' );
my $ja2 = $schema->resultset('JournalsAuth')->find({ title => 'Journal Title Local' });
isnt( $ja2, undef, 'local load: journal auth record found by title');

my $ja3 = $schema->resultset('JournalsAuth')->find({ title => [ 'Journal Title Second', 'Journal Title Second Alternate' ] });
isnt( $ja3, undef, 'local load: journal auth record found by titles');
is_deeply( [ sort map { $_->issn }  $ja3->issns->all  ], [ '22223333', '33334444' ], 								   								 'local load: journal auth expected issns' );
is_deeply( [ sort map { $_->title } $ja3->titles->all ], [ 'Journal Title Local Second', 'Journal Title Second', 'Journal Title Second Alternate' ], 'local load: journal auth expected titles' );
is( $ja3->global_journals->count, 2, 'local load: journal auth correct number of linked global journals' );
is( $ja3->local_journals->count,  1, 'local load: journal auth correct number of linked local journals' );
