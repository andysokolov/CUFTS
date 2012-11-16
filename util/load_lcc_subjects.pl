#!/usr/local/bin/perl

use lib qw (lib);

use strict;

use CJDB::DB::LCCSubjects;
use CUFTS::DB::Sites;
use CUFTS::Exceptions;
use Getopt::Long;

# Read command line arguments

my %options;
GetOptions(\%options, 'site_key=s', 'site_id=i');
my @files = @ARGV;

# Get CUFTS site id

my $site_id = get_site_id();   

# Delete existing entries

CJDB::DB::LCCSubjects->search('site' => $site_id)->delete_all;

foreach my $file (@files) {

	open INPUT, $file or 
		die "Unable to open input file: $!";
	
	while (<INPUT>) {
	
		chomp;
	
		my $record = {};
		($record->{'class_low'},
		 $record->{'number_low'},
		 $record->{'class_high'},
		 $record->{'number_high'},
		 $record->{'subject1'},
		 $record->{'subject2'},
		 $record->{'subject3'}) = split /\t/, $_;

		# Clean up quotes from Excel

		$record->{'subject1'} =~ s/^"//;
		$record->{'subject1'} =~ s/"$//;
		$record->{'subject2'} =~ s/^"//;
		$record->{'subject2'} =~ s/"$//;
		$record->{'subject3'} =~ s/^"//;
		$record->{'subject3'} =~ s/"$//;

		$record->{'site'} = $site_id;
		
		CJDB::DB::LCCSubjects->create($record);

	}

	close INPUT;
}

CJDB::DB::LCCSubjects->dbi_commit;

sub get_site_id {
	defined($options{'site_id'}) and
		return $options{'site_id'};

	my @sites = CUFTS::DB::Sites->search('key' => $options{'site_key'});
	
	scalar(@sites) == 1 and
		return $sites[0]->id;
		
	return undef;
}


sub usage {
	print <<EOF;
	
load_lcc_subjects - Loads a tab delimited file of call number ranges and subjects

 site_key=XXX - CUFTS site key (example: BVAS)
 site_id=111  - CUFTS site id (example: 23)
 
EOF
}
