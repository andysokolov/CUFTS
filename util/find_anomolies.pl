#!/usr/local/bin/perl

use strict;

use lib 'lib';
use MARC::Record;
use MARC::Batch;

use Data::Dumper;

my $batch = MARC::Batch->new('USMARC', @ARGV);
$batch->strict_off;

my %stats;

while (my $record = $batch->next()) {
	$stats{count}++;
	
	my @issns_a;
	foreach my $issn_field ($record->field('022')) {
		my $issn = $issn_field->subfield('a');
		$issn = uc($issn);
		$issn =~ s/.*(\d{4})-?(\d{3}[\dX]).*/$1$2/ or
			next;
		push @issns_a, $issn;
	}

	if (scalar(@issns_a) > 1) {
		$stats{multiple_a_fields}++;
		
		# Check 780 fields
		
		my @x_fields;
		foreach my $alt_field ($record->field('78.')) {
			my $x_field = $alt_field->subfield('x');

			$x_field = uc($x_field);
			$x_field =~ s/.*(\d{4})-?(\d{3}[\dX]).*/$1$2/ or
				next;

			if (grep {$_ eq $x_field} @issns_a) {
				print "78.x field matches 022a field for title: ", $record->title, "\n";
				$stats{'78.x match'}++;
			}
		}
	}
}

warn(Dumper(\%stats));




