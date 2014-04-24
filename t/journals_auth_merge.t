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

my $cjdb_account = $schema->resultset('CJDBAccounts')->create({
    name => 'Test Account',
    site => $site->id,
    email => 'test@test.com',
    key => 'test',
    password => 'test',
});


# Setup some journal auth records

my $ja1 = $schema->resultset('JournalsAuth')->create({
    title  => 'Journal of First Test',
    titles => [ { title => 'Journal of First Test', title_count => 1 }, { title => 'Journal of First Test Society', title_count => 2 } ],
    issns  => [ { issn => '11112222' }, { issn => '2222-555x' } ],
    cjdb_tags => [
        {
            tag => 'testtag1',
            site => $site->id,
            account => $cjdb_account->id,
        },
    ],
});

my $ja2 = $schema->resultset('JournalsAuth')->create({
    title  => 'Journal of Second Test',
    titles => [ { title => 'Journal of Second Test', title_count => 15 }, { title => 'Second Journal of Testing', title_count => 12 } ],
    issns  => [ { issn => '56564421' } ],
    cjdb_tags => [
        {
            tag => 'testtag2',
            site => $site->id,
            account => $cjdb_account->id,
        },
    ],
});

my $ja3 = $schema->resultset('JournalsAuth')->create({
    title  => 'Journal of Third Test',
    titles => [ { title => 'Journal of Third Test', title_count => 5 }, { title => 'Another Test Journal', title_count => 3 } ],
    issns  => [],
});

my $ja4 = $schema->resultset('JournalsAuth')->create({
    title  => 'Journal of Fourth Test',
    titles => [ { title => 'Journal of Fourth Test', title_count => 6 }, { title => 'Another Test Journal', title_count => 2 } ],
    issns  => [],
});

my $ja5 = $schema->resultset('JournalsAuth')->create({
    title  => 'Journal of Fifth Test',
    titles => [ { title => 'Journal of Fifth Test', title_count => 16 } ],
    issns  => [ { issn => '5656-4421' } ],
});

# Create some associated records that should be updated.

my $resource1 = $schema->resultset('GlobalResources')->create({
    name          => 'Test Global Resource 1',
    key           => 'global_resource_1',
    resource_type => { type => 'Test Type 1' },
    provider      => 'Test Provider',
    module        => 'Test Module,'
});

my $journal1 = $resource1->add_to_global_journals({
    title        => 'Journal Title Second',
    issn         => '11112222',
    journal_auth => $ja2->id,
});

my $local_resource1 = $schema->resultset('LocalResources')->create({
    name          => 'Test Local Resource 1',
    resource_type => { type => 'Test Type 1' },
    site		  => 1,
    provider      => 'Test Provider',
    module        => 'Test Module,'
});

my $local_journal1 = $local_resource1->add_to_local_journals({
    title        => 'Journal Title Second Local',
    journal_auth => $ja2->id,
    active       => 't',
});

my $local_journal2 = $local_resource1->add_to_local_journals({
    title        => 'Journal That Is Not Updated',
    journal_auth => $ja3->id,
    active       => 't',
});

# CJDB Journals to merge

my $cjdb_journal1 = $schema->resultset('CJDBJournals')->create({
    site => $site->id,
    journals_auth => $ja1->id,
    title => 'CJDB Journal 1',
    sort_title => 'cjdb journal 1',
    stripped_sort_title => 'cjdb journal 1',
    issns => [ { issn => '11112222', site => $site->id } ],
    links => [
        {
            site => $site->id,
            link_type => 1,
            url => 'http://url1/',
        },
    ],
    journals_titles => [
        {
            title => { title => 'CJDB Journal Title 1', search_title => 'cjdb journal title 1' },
            site => $site->id,
            main => 1,
        },
    ],
    journals_subjects => [
        {
            subject => { subject => 'CJDB Journal Subject 1', search_subject => 'cjdb journal subject 1' },
            site => $site->id,
        },
    ],
    journals_associations => [
        {
            association => { association => 'CJDB Journal Association 1', search_association => 'cjdb journal association 1' },
            site => $site->id,
        },
    ],
    relations => [
        {
            relation => 'Relation 1',
            title    => 'CJDB Journal Relation 1',
            issn => '99998888',
            site => $site->id,
        },
    ],
});

my $cjdb_journal2 = $schema->resultset('CJDBJournals')->create({
    site => $site->id,
    journals_auth => $ja2->id,
    title => 'CJDB Journal 2',
    sort_title => 'cjdb journal 2',
    stripped_sort_title => 'cjdb journal 2',
    issns => [ { issn => '22223333', site => $site->id } ],
    links => [
        {
            site => $site->id,
            link_type => 1,
            url => 'http://url2/',
        },
    ],
    journals_titles => [
        {
            title => { title => 'CJDB Journal Title 2', search_title => 'cjdb journal title 2' },
            site => $site->id,
            main => 1,
        },
    ],
    journals_subjects => [
        {
            subject => { subject => 'CJDB Journal Subject 2', search_subject => 'cjdb journal subject 2' },
            site => $site->id,
        },
    ],
    journals_associations => [
        {
            association => { association => 'CJDB Journal Association 2', search_association => 'cjdb journal association 2' },
            site => $site->id,
        },
    ],
    relations => [
        {
            relation => 'Relation 2',
            title    => 'CJDB Journal Relation 2',
            issn => '33334444',
            site => $site->id,
        },
    ],

});

# Quick sanity check

my $r1 = $schema->resultset('JournalsAuth')->find({ title => { 'ilike' => 'journal of first test' } });
is($r1->title, 'Journal of First Test');
my @issns = sort map { $_->issn } $r1->issns->all;
is_deeply( \@issns, [ '11112222', '2222555X' ], 'issns cleaned and loaded' );

is( $schema->resultset('CJDBTags')->count, 2, 'cjdb tags sanity count');
is( $ja1->cjdb_tags->count, 1, 'cjdb tags attached 1' );
is( $ja2->cjdb_tags->count, 1, 'cjdb tags attached 2' );

CUFTS::JournalsAuth->merge( $schema, $ja1->id, $ja2->id, $ja5->id );

# Check that the Journal Auth parts got merged properly

my $check_deleted = $schema->resultset('JournalsAuth')->search({ id => 2 })->count;
is( $check_deleted, 0, 'merged journal auth deleted');

my $merged1 = $schema->resultset('JournalsAuth')->find({ id => 1 });
isnt( $check_deleted, undef, 'merged journal auth exists');

is( $merged1->title, 'Journal of First Test', 'merged record kept main title');
@issns = sort map { $_->issn } $merged1->issns->all;
is_deeply( \@issns, [ '11112222', '2222555X', '56564421' ], 'merged issns' );

my @titles = sort map { $_->title } $merged1->titles->all;
is_deeply( \@titles, [ 'Journal of Fifth Test', 'Journal of First Test', 'Journal of First Test Society', 'Journal of Second Test', 'Second Journal of Testing' ], 'merged titles' );

# Check associated CJDB tags

is( $schema->resultset('CJDBTags')->count, 2, 'cjdb tags not lost');
is( $merged1->cjdb_tags->count, 2, 'cjdb tags merged count' );
is_deeply( [ sort map { $_->tag } $merged1->cjdb_tags->all ], [ 'testtag1', 'testtag2' ], 'cjdb tags merged deeply' );


# Check that assocatiated Global and Local journals got merged

my $check_j1 = $resource1->global_journals({ id => 1 })->first;
is( $check_j1->journal_auth->id, $merged1->id, 'global journals link updated' );

$check_j1 = $local_resource1->local_journals({ id => 1 })->first;
is( $check_j1->journal_auth->id, $merged1->id, 'local_resource1 journals link updated' );

$check_j1 = $local_resource1->local_journals({ id => 2 })->first;
is( $check_j1->journal_auth->id, $ja3->id, 'local_resource1 journals did not update other journals' );

# Check that any associated CJDB records got merged

my $check_cjdb1 = $schema->resultset('CJDBJournals')->find({ id => 1 });
is( $check_cjdb1->titles->count, 	   2, 'cjdb titles moved' );
is( $check_cjdb1->issns->count, 		2, 'cjdb issns moved' );
is( $check_cjdb1->links->count, 		2, 'cjdb links moved' );
is( $check_cjdb1->subjects->count, 	 2, 'cjdb subjects moved' );
is( $check_cjdb1->associations->count,  2, 'cjdb associations moved' );
is( $check_cjdb1->relations->count, 	2, 'cjdb relations moved' );

is_deeply( [ sort map { $_->title } $check_cjdb1->titles->all ], ['CJDB Journal Title 1', 'CJDB Journal Title 2'], 'cjdb deep title check' );

my $check_cjdb2 = $schema->resultset('CJDBJournals')->find({ id => 2 });
is( $check_cjdb2, undef, 'cjdb merged record removed');
