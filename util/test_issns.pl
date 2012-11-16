#!/usr/local/bin/perl

use lib qw(lib);

use Business::ISSN;
use CUFTS::DB::JournalsAuth;

my $journals_iter = CUFTS::DB::JournalsAuth->retrieve_all();

my $count = 0;
while (my $journal = $journals_iter->next) {
	my ($issn_bad, $e_issn_bad);

	defined($journal->issn) && !Business::ISSN::is_valid_checksum($journal->issn) and
		$issn_bad = 1;

	defined($journal->e_issn) && !Business::ISSN::is_valid_checksum($journal->e_issn) and
		$e_issn_bad = 1;

	if ($issn_bad || $e_issn_bad) {
		$count++;
		print sprintf("%-80s", substr($journal->title,0,80));
		if (defined($journal->issn)) {
			print $issn_bad ? ('*' . $journal->issn . '*') : (' ' . $journal->issn . ' '); 
			print "  ";
		}			
		
		if (defined($journal->e_issn)) {
			print $e_issn_bad ? ('*' . $journal->e_issn . '*') : (' ' . $journal->e_issn . ' ');
		}			
		
		print "\n";
	}
}

	
print "\n\n--\n$count bad ISSNs found\n";