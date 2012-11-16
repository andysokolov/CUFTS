#!/usr/local/bin/perl

use lib qw(lib);

use CUFTS::DB::Resources;
use CUFTS::DB::ResourceTypes;
use CUFTS::DB::Services;

my @resources = CUFTS::DB::Resources->search('active' => 't', {'order_by' => 'provider, name'});


if ($ARGV[0] eq '-h') {
	print '<table border="0" cellspacing="1" cellpadding="1" bgcolor="#004997">';
	print '<tr><td class="heading-bar">resource</td><td class="heading-bar">provider</td><td class="heading-bar">supported links</td></tr>';

	my $count = 0;
	foreach my $resource (@resources) {
		$count++;
		my $class = 'field' . ($count % 2);

		print "<td class=\"$class\">" . $resource->name . '</td>';
		print "<td class=\"$class\">" . $resource->provider . '</td>';
		my @services = $resource->services;
		print "<td class=\"$class\">";
		print join ", ", map {$_->name} sort {$a->name cmp $b->name} @services;
		print "</td></tr>\n";
	}
	print '</table>';
} else {
	foreach my $resource (@resources) {
		print $resource->name, ' - ', $resource->provider, ' - ';
		my @services = $resource->services;
		print join ", ", map {$_->name} sort {$a->name cmp $b->name} @services;
		print "\n";
	}
}
