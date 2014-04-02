#!/usr/local/bin/perl

use lib qw (lib);

use strict;


use CUFTS::Config;
use CUFTS::Exceptions;
use Getopt::Long;

# Read command line arguments

my %options;
GetOptions(\%options, 'site_key=s', 'site_id=i');
my @files = @ARGV;

my $schema = CUFTS::Config::get_schema();

##
## Load the site
##

my $site;
if ( $options{site_id} ) {
	$site = $schema->resultset('Sites')->find({ id => int($options{site_id}) });
}
elsif ( $options{site_key} ) {
	$site = $schema->resultset('Sites')->find({ key => $options{site_key} });
}
else {
	usage();
	exit;
}
if ( !$site ) {
	die("Unable to load site or site key/id was not passed in.");
}
my $site_id = $site->id;

# Delete existing entries


sub load_subjects {
	my ( $site ) = @_;

	$site->cjdb_lcc_subjects->delete_all;

	foreach my $file (@files) {

		open INPUT, $file or
			die "Unable to open input file: $!";

		while (<INPUT>) {

			chomp;

			my $record = {};
			($record->{class_low},
			 $record->{number_low},
			 $record->{class_high},
			 $record->{number_high},
			 $record->{subject1},
			 $record->{subject2},
			 $record->{subject3}) = split /\t/, $_;

			# Clean up quotes from Excel

			$record->{subject1} =~ s/^"//;
			$record->{subject1} =~ s/"$//;
			$record->{subject2} =~ s/^"//;
			$record->{subject2} =~ s/"$//;
			$record->{subject3} =~ s/^"//;
			$record->{subject3} =~ s/"$//;

			$site->add_to_cjdb_lcc_subjects($record);

		}

		close INPUT;
	}
}


sub usage {
	print <<EOF;

load_lcc_subjects - Loads a tab delimited file of call number ranges and subjects

 site_key=XXX - CUFTS site key (example: BVAS)
 site_id=111  - CUFTS site id (example: 23)

EOF
}
