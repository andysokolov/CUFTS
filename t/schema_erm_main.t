use strict;
use warnings;

use Test::More tests => 25;

use Test::DBIx::Class {
    schema_class => 'CUFTS::Schema',
    connect_info => ['dbi:Pg:dbname=CUFTStesting','CUFTStesting','', { quote_names => 1 }],
    force_drop_table  => 1,
    fail_on_schema_break => 1,
};

my $schema = Schema;
my $timestamp = $schema->get_now();
like($timestamp, qr/^[-\d]+\s[-\.:\d]+$/, 'timestamp as extra check that TestDatabase loaded');

# Setup basic testing data

my $site = $schema->resultset('Sites')->create({
	name         => 'Test University',
	active       => 'true',
	proxy_prefix => 'PROXY:',
});

my $subject1 = $schema->resultset('ERMSubjects')->create({
	site    => $site->id,
	subject => 'Test Subject 1',
});

my $ct1 = $schema->resultset('ERMContentTypes')->create({
	site         => $site->id,
	content_type => 'Test Type 1',
});

my $erm1 = $schema->resultset('ERMMain')->create({
	site 	=> $site->id,
	key  	=> 'test_erm_main1',
	url  	=> 'http://www.test1.com/',
	proxy 	=> 'f',
	subjects_main      => [{ subject => $subject1->id, rank => 1 }],
	content_types_main => [{ content_type => $ct1->id }],
});
$erm1->main_name('Test ERM Main 1');
$erm1->add_to_uses({});

my $erm2 = $schema->resultset('ERMMain')->create({
	site 	=> $site->id,
	key  	=> 'test_erm_main2',
	url  	=> 'http://www.test2.com/',
	proxy 	=> 't',
	subjects_main      => [{ subject => $subject1->id, rank => 1 }],
	content_types_main => [{ content_type => $ct1->id }],
});
$erm2->main_name('Test ERM Main 2');

ok( defined $erm1, 'ERM record created' );
ok( $erm1->id > 0, 'ERM record has created id');
is( $erm1->name, 'Test ERM Main 1', 'main name set correctly, name fallback works');
isa_ok($erm1->as_marc, 'MARC::Record');

is( $erm1->proxied_url, 'http://www.test1.com/', 'proxied_url with proxy set to false');
is( $erm2->proxied_url, 'PROXY:http://www.test2.com/', 'proxied_url with proxy set to true');

my $hash = $erm1->to_hash();
is( ref $hash, 'HASH', 'converted to HASHREF');
is( $hash->{name}, 'Test ERM Main 1', 'Name flattened to "name"');

my $erm3 = $erm1->clone();
ok( defined $erm3, 'cloned ERM record created' );
ok( $erm3->id > 0, 'cloned ERM record has created id');
is( $erm3->key, 'Clone of ' . $erm1->key, 'cloned key has prefix added');
is( $erm3->main_name, 'Clone of ' . $erm1->main_name, 'cloned name has prefix added');
is( $erm3->subjects->count, 1, 'cloned subject_main' );
is( $erm3->content_types->count, 1, 'cloned content_types_main' );
is( $erm3->names->count, 1, 'cloned single name record' );
$erm3->add_to_names({ name => 'New Clone Name', main => 0 });


# Check cascade_copy

is( $schema->resultset('ERMContentTypes')->count, 1, 'clone did not create second base content type');
is( $schema->resultset('ERMContentTypesMain')->count, 3, 'clone created single additional content type link');
is( $schema->resultset('ERMSubjects')->count, 1, 'clone did not create second base subject');
is( $schema->resultset('ERMSubjectsMain')->count, 3, 'clone created single additional subject link');

# Make sure we don't cascade_copy uses

is( $schema->resultset('ERMUses')->count, 1, 'clone created single additional subject link');
is( $erm3->uses->count, 0, 'cloned single name record' );

# Test some advanced searches

my $fs_rs = $schema->resultset('ERMMain')->facet_search( $site->id, { name => 'n' });
is( $fs_rs->count, 1, 'facet_search: returned correct number from facet_search.' );
my $fs_erm1 = $fs_rs->first;
is( $fs_erm1->result_name, 'New Clone Name', 'facet_search: correct name from result_name' );
is( $fs_erm1->name, 'New Clone Name', 'facet_search: correct name from name' );

1;
