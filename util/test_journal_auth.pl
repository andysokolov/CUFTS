#!/usr/local/bin/perl

use strict;

use lib 'lib';

use CUFTS::DB::JournalsAuth;
use CUFTS::DB::JournalsAuthTitles;
use CUFTS::CJDB::Util;

my $iter = CUFTS::DB::JournalsAuth->retrieve_all();
#my $iter = CUFTS::DB::JournalsAuth->search(id => 18817);
my $count = 0;
my $bad = 0;
while (my $journal = $iter->next) {
	$count++;
	my @titles = map {$_->title} $journal->titles;
	next unless scalar(@titles) > 1;
	my $title = $journal->title;

TITLES:	
	foreach my $alt_title (@titles) {

		unless (CUFTS::CJDB::Util::title_match([$title], [$alt_title])) {
			print "------------------------------\n";
			print "Record id: ", $journal->id, "\n";
			my @issns = $journal->issns;

			foreach my $issn (@issns) {
				print "ISSN     : ", $issn->issn, "\n";
			}

			print "Title    : ", $journal->title, "\n";
			foreach my $title (@titles) {
				print "Other    : ", $title, "\n";
			}

			$bad++;
			last TITLES;
		}
	}
}		

print "\n\nBad: $bad\nTotal: $count\n";