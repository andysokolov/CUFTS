#!/usr/local/bin/perl

use lib qw (lib);

use strict;

use MARC::Batch;
use MARC::Record;
use Business::ISSN;

#$MARC::Record::DEBUG = 1;

my $batch = MARC::Batch->new('USMARC', @ARGV);
$batch->strict_off();

my $count = 0;
while (my $record = $batch->next()) {
	$count++;

	my $title = $record->field('245')->as_string;
	my @errs;

	foreach my $issn_field ($record->field('022')) {
		foreach my $subfield ('a'..'z') {
			my $issn = $issn_field->subfield($subfield);
						
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
		print "$title\n";
		print join "\n", @errs;
		print "\n";
		print "------------------------------------------\n";
	}

}

sub clean_issn {
        my ($self, $issn) = @_;
        
        $issn =~ s/-//;
        $issn = uc($issn);
        $issn =~ s/^\s+//;
        $issn =~ s/\s+$//;
 
        return $issn;
}        

