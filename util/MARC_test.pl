#!/usr/local/bin/perl

use lib qw (lib);

use strict;

use MARC::Batch;
use MARC::Record;

$MARC::Record::DEBUG = 1;

use CJDB::DB::Journals;
use CJDB::DB::Titles;
use CJDB::DB::Subjects;
use CJDB::DB::Links;

my $batch = MARC::Batch->new('USMARC', '/home/tholbroo/BNMSerials1.mrc');
$batch->strict_off();
my $site = 14;
my $count = 0;

while (my $record = $batch->next()) {
	$count++;

#	last if $count > 20;

	print "-----\n";

	my $title = $record->title;
	$title =~ s/\s+--\s*$//;
	$title =~ s/\.$//;
	print "$title\n";

	my $sort_title = strip_title(substr($title, $record->field('245')->indicator('2')));
	print "$sort_title\n";

	my @issns;
	foreach my $issn_field ($record->field('022')) {
		foreach my $issn (split / /, $issn_field->as_string) {
			$issn =~ s/-//;
			$issn = uc($issn);
			$issn =~ s/^\s+//;
			$issn =~ s/\s+$//;
			if ($issn !~ /^\d{7}[\dX]$/) {
				warn('BAD ISSN: ' . $issn);
				next;
			}
			push @issns, $issn;
		}
	}

	scalar(@issns) > 2 and
		warn("More than two ISSNs for '$title': ", join ',', @issns);

	print join ',', @issns;
	print "\n";

	next unless defined($title);

	my $journal = CJDB::DB::Journals->create({
		'title' => $title,
		'issn1' => shift(@issns),
		'issn2' => shift(@issns),
		'sort_title' => $sort_title,
		'site' => $site,
	});
	my $journal_id = $journal->id;

	my @search_titles;

	my $stripped_title = strip_title($title);
	my $stripped_sort_title = strip_title($sort_title);

	push @search_titles, [$stripped_title, $title];
	$stripped_title ne $stripped_sort_title and
		push @search_titles, [$stripped_sort_title, $title];

	my @alt_titles = $record->field('246');
	foreach my $alt_title (@alt_titles) {
		my $temp_title = $alt_title->subfield('a');
		defined($alt_title->subfield('b')) and
			$temp_title .= ' ' . $alt_title->subfield('b');
		defined($alt_title->subfield('n')) and
			$temp_title .= ' ' . $alt_title->subfield('n');
		defined($alt_title->subfield('p')) and
			$temp_title .= ' ' . $alt_title->subfield('p');

		push @search_titles, [strip_title($temp_title), $temp_title];
	}

	foreach my $title (@search_titles) {
		defined($title->[0]) && $title->[0] ne '' && defined($title->[1]) && $title->[1] ne '' or
			next;
		CJDB::DB::Titles->create({
			'journal' => $journal_id,
			'site' => $site,
			'search_title' => $title->[0],
			'title' => $title->[1], 
		});
	}
	
	my @subjects = $record->field('6..');
	foreach my $subject (@subjects) {

		my $subject_string = $subject->as_string;
		$subject_string =~ s/\.$//;		# Remove trailing period

		CJDB::DB::Subjects->find_or_create({
			'journal' => $journal_id,
			'site' => $site,
			'subject' => $subject_string,
			'search_subject' => strip_title($subject_string),
		});
	}

	my @associations = $record->field('110');
	push @associations, $record->field('710');
	foreach my $association (@associations) {

		my $association_string = $association->as_string;
		$association_string =~ s/\.$//;		# Remove trailing period

		CJDB::DB::Associations->find_or_create({
			'journal' => $journal_id,
			'site' => $site,
			'association' => $association_string,
			'search_association' => strip_title($association_string),
		});
	}

	my @three_fives = $record->field('035');
	my $bnum = $three_fives[0]->subfield('a');
	$bnum = substr($bnum, 1);   # Strip leading period
	chop $bnum;                 # Strip check digit

	my $coverage_string;
	my @coverages = $record->field('590');
	foreach my $coverage (@coverages) {
		defined($coverage_string) and
			$coverage_string .= '; ';
		$coverage_string .= $coverage->as_string;
	}
	
	CJDB::DB::Links->create({
		'journal' => $journal_id,
		'name' => 'Malaspina University-College Print Holdings',
		'link_label' => 'Link to this print journal in the catalogue',
		'url' => "http://marlin.mala.bc.ca/malabin/door.pl/0/0/60/332/X",
		'print_coverage' => $coverage_string || 'unknown',
	});
		


	CJDB::DB::DBI->dbi_commit;

}

sub strip_title {
	my ($string) = @_;
	
	$string = lc($string);
	$string =~ s/\.//g;
	$string =~ s/[^a-z0-9]/ /g;
	$string =~ s/\s\s+/ /g;
	$string =~ s/\s+$//g;	
	$string =~ s/^\s+//g;	

	return $string;
}
