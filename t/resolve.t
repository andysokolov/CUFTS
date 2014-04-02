use strict;

use Test::More tests => 5;

use Test::DBIx::Class {
	schema_class => 'CUFTS::Schema',
	connect_info => ['dbi:Pg:dbname=CUFTStesting','CUFTStesting','', { quote_names => 1 }],
	force_drop_table  => 1,
	fail_on_schema_break => 1,
};

my $schema = Schema;
my $timestamp = $schema->get_now();
like($timestamp, qr/^[-\d]+\s[-\.:\d]+$/, 'timestamp as extra check that TestDatabase loaded');

BEGIN {
	use_ok('CUFTS::Resolve');
}

my $site = $schema->resultset('Sites')->create({
	name         => 'Test University',
	active       => 'true',
	proxy_prefix => 'PROXY:',
});

my $global_resource = $schema->resultset('GlobalResources')->create({
	name          => 'Test Resource One',
	key           => 'global_resource',
	provider      => 'Test Provider',
	module        => 'Test Module',
	resource_type => { type => 'Test Type 1' },
	active        => 't',
});

my $local_resource = $schema->resultset('LocalResources')->create({
	resource		 => $global_resource->id,
	site 			=> $site->id,
	active 		  => 't',
	cjdb_note		=> 'CJDB Note',
	proxy			=> 't',
});

my $global_journal1 = $global_resource->add_to_global_journals({
	title        => 'Journal One',
});

my $global_journal2 = $global_resource->add_to_global_journals({
	title        => 'Journal Two',
	issn         => '11112222',
});

my $global_journal3 = $global_resource->add_to_global_journals({
	title        => 'Journal Three',
	issn         => '33334444',
});

my $local_journal1 = $local_resource->add_to_local_journals({
	journal => $global_journal1->id,
	active	=> 't',
});

my $local_journal2 = $local_resource->add_to_local_journals({
	journal => $global_journal2->id,
	active	=> 't',
});

my $local_journal3 = $local_resource->add_to_local_journals({
	journal => $global_journal3->id,
	active	=> 't',
});

##
## Test merging local and global resource data.
##

my $overlay_resource = CUFTS::Resolve->overlay_global_resource_data($local_resource);
is( $overlay_resource->name, 'Test Resource One', 'overlay: name overlay');
is( $overlay_resource->proxy, 't', 'overlay: proxy true');
is( $overlay_resource->resource_type, 'Test Type 1', 'overlay: resource type flattened');

1;
