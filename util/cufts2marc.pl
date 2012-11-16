#!/usr/local/bin/perl

use lib qw(lib);

use strict;

use CUFTS::DB::Resources;
use CUFTS::DB::ResourceTypes;
use CUFTS::DB::Journals;

use CUFTS::Config;

use CUFTS::Request;

warn('1');

my $resource = FakeLocalResource->retrieve(1);

warn('2');

my $module = $CUFTS::Config::CUFTS_MODULE_PREFIX . $resource->module;

print "$module\n";

eval "require $module";
if ($@) {
	die("Error requiring module: $@");
}

warn('3');

$module->can("build_linkJournal") or
	die("Module does not support building journal level links.");

my $site = new FakeSite;

foreach my $journal (CUFTS::DB::Journals->search('resource' => $resource->id)) {

	my $request = new CUFTS::Request;
	$request->title($journal->title);
	$request->issn($journal->issn);

	my $results = $module->build_linkJournal([$journal], $resource, $site, $request);
	
	foreach my $result (@$results) {
		print join ", ", $journal->title, $journal->issn, $result->url;
		print "\n";
	}
}


package FakeSite;

sub new { return bless {}, shift };
sub key { 'cufts2marc' };
sub name { 'cufts2marc' };
sub proxy_prefix { '' };
sub email { '' };
sub active { 1 };

package FakeLocalResource;

use base qw(CUFTS::DB::Resources);
sub proxy { 0 };

1;
