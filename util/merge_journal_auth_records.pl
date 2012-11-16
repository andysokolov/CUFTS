#!/usr/local/bin/perl

use lib 'lib';


use CUFTS::DB::LocalJournals;
use CUFTS::DB::Journals;
use CUFTS::DB::JournalsAuth;
use CJDB::DB::Journals;
use CJDB::DB::Tags;
use CUFTS::Util::Simple;


while (my $title = <>) {
	$title = trim_string($title);

	my @journal_auths = CUFTS::DB::JournalsAuth->search('title' => $title);
	scalar(@journal_auths) > 1 or next;
	
	# Merge down to the first one... doesn't really matter
	
	my $new_journal_auth = shift(@journal_auths);

	print "Merging down to: ", $new_journal_auth->title, "\n";
	
	foreach my $journal_auth (@journal_auths) {
		foreach my $j_a_title ($journal_auth->titles) {
			my @existing_titles = CUFTS::DB::JournalsAuthTitles->search('title' => $j_a_title->title, 'journal_auth' => $new_journal_auth->id);
			next if scalar(@existing_titles);

			print " Merging title: ", $j_a_title->title, "\n";
			
			$j_a_title->journal_auth($new_journal_auth->id);
			$j_a_title->update;
		}
		
		foreach my $j_a_issn ($journal_auth->issns) {
			print " Merging ISSN: ", $j_a_issn->issn, "\n";

			$j_a_issn->journal_auth($new_journal_auth->id);
			$j_a_issn->update;
		}

		my @journals = CUFTS::DB::Journals->search('journal_auth' => $journal_auth->id);
		foreach my $journal (@journals) {
			$journal->journal_auth($new_journal_auth->id);
			$journal->update;
		}
		@journals = CUFTS::DB::LocalJournals->search('journal_auth' => $journal_auth->id);
		foreach my $journal (@journals) {
			$journal->journal_auth($new_journal_auth->id);
			$journal->update;
		}
		@journals = CJDB::DB::Journals->search('journals_auth' => $journal_auth->id);
		foreach my $journal (@journals) {
			$journal->journals_auth($new_journal_auth->id);
			$journal->update;
		}
		@journals = CJDB::DB::Tags->search('journals_auth' => $journal_auth->id);
		foreach my $journal (@journals) {
			$journal->journals_auth($new_journal_auth->id);
			$journal->update;
		}
		
		$journal_auth->delete;
	}
	
	$new_journal_auth->marc(undef);
	$new_journal_auth->update;
}


		
CUFTS::DB::DBI->dbi_commit;
