#!/usr/local/bin/perl

use lib qw (lib);

use strict;

use MARC::Batch;
use MARC::Record;
use Business::ISSN;
use String::Util qw(hascontent trim);


#$MARC::Record::DEBUG = 1;

my $batch = MARC::Batch->new('USMARC', @ARGV);
$batch->strict_off();

my $count = 0;
while (my $record = $batch->next()) {
	$count++;

	my $title = $record->title;
	my @errs;

	if ( !hascontent($title) ) {
		push @errs, "Title not found in 245 field."
	}

	foreach my $issn_field ($record->field('022')) {
		foreach my $subfield ('a'..'z') {
			my $issn = clean_issn( $issn_field->subfield($subfield) );

			next unless $issn =~ /\S/;  # Make sure it's not all whitespace

			if ($issn !~ /^\d{4}\-?\d{3}[\dXx]$/) {
				push @errs, "ISSN does not match ISSN pattern: $issn";
			} elsif ($subfield ne 'y' && !Business::ISSN::is_valid_checksum($issn)) {
				push @errs, "ISSN fails checksum: $issn";
			}
		}
	}

	if (scalar(@errs)) {
		print "Record $count\n";
		print "$title\n" || "Missing title\n";
		print join "\n", @errs;
		print "\n";
		print "------------------------------------------\n";
	}

}

print "Parser found $count records.\n";

sub clean_issn {
        my $issn = shift;

        $issn =~ s/-//;
        $issn = trim(uc($issn));

        return $issn;
}
