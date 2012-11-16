#!/usr/local/bin/perl

use strict;
use DBI;
use Data::Dumper;

use lib qw(lib);

my $dbh = DBI->connect('dbi:Pg:dbname=stats_test', 'tholbroo', '');

my @fields = qw(
	request_date
	request_site
	
	genre
	issn
	eissn
	title
	atitle
	volume
	issue
	spage
	epage
	pages
	date
	doi

	aulast
	aufirst
	auinit
	auinit1
	auinitm

	artnum
	part
	coden
	isbn
	sici
	bici
	stitle

	ssn
	quarter
		
	oai
	pmid
	bibcode

	id
	sid
);

main();


sub main {
	my $sth = $dbh->prepare('INSERT INTO stats (request_date, request_time, site, issn, isbn, title, volume, issue, date, doi, results) VALUES (?,?,?,?,?,?,?,?,?,?,?)');

	my $previous_record;
	while (<>) {
		chomp;
		my $record = parse_line($_);

		defined($record) or next;
		next if check_dupe($record, $previous_record);
		
		my $site = $record->{'request_site'};
		next if $site eq 'UNKNOWN';

		my @values;
		push @values, split / /, $record->{'request_date'};
		push @values, $record->{'request_site'};
		push @values, (defined($record->{'issn'}) ? $record->{'issn'} : $record->{'eissn'});
		push @values, $record->{'isbn'};
		push @values, (defined($record->{'title'}) ? $record->{'title'} : $record->{'stitle'});
		push @values, $record->{'volume'};
		push @values, $record->{'issue'};
		push @values, $record->{'date'};
		push @values, $record->{'doi'};
		push @values, ((defined($record->{'results'}) && $record->{'results'} ne '') ? 't' : 'f');

		$sth->execute(@values);

		$previous_record = $record;
	}
}

sub check_dupe {
	my ($new, $old) = @_;
	return 0 unless defined($old);

	foreach my $field (qw(genre issn isbn eissn title atitle volume issue spage epage pages date)) {
		if ($new->{$field} ne $old->{$field}) {
			return 0;
		}
	}
	
	return 1;
}


sub parse_line {
	my ($line) = @_;
	
	return undef unless $line =~ /^\d{8}/;

	my $record = {};
	
	my @line = split /\t/, $line;
	foreach my $x (0 .. $#fields) {
		$record->{$fields[$x]} = shift @line;
	}
	scalar(@line) > 0 and
		$record->{'results'} = "@line";


	return $record;
}

sub parse_date {
	my ($date) = @_;
	
	return split / /, $date, 2;
}
