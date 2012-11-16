#!/usr/local/bin/perl

##
## This script checks all CUFTS sites for files that are
## marked for reloading.
##

use lib qw(lib);

use CUFTS::Exceptions;
use CUFTS::Config;
use CUFTS::DB::Sites;

use strict;

my $site_iter = CUFTS::DB::Sites->retrieve_all;
while (my $site = $site_iter->next) {
	print "Checking " . $site->name . "\n";
	
	unless ( (defined($site->rebuild_cjdb) && $site->rebuild_cjdb ne '') ||
	         (defined($site->rebuild_ejournals_only) && $site->rebuild_ejournals_only eq '1') ){
		next;
	}

	print " * Found files marked for rebuild.\n";
	
	# First load any LCC subject files

	my $site_id = $site->id;	
	if (-e "${CUFTS::Config::CJDB_SITE_DATA_DIR}/${site_id}/lccn_subjects") {
		`util/load_lcc_subjects.pl --site_id=${site_id}  ${CUFTS::Config::CJDB_SITE_DATA_DIR}/${site_id}/lccn_subjects`;
		`util/create_subject_browse.pl --site_id=${site_id}`;
	}

	my @files = split /\|/, $site->rebuild_cjdb;
	my $site_id = $site->id;

	my $count = 0;
	foreach my $file (@files) {

		print " * Loading print records from $file\n";

		$file = $CUFTS::Config::CJDB_SITE_DATA_DIR . '/' . $site_id . '/' .$file;

		if ($count == 0) {
			`util/load_print_records.pl --site_id=${site_id} "$file"`;
		} else {
			`util/load_print_records.pl --append --site_id=${site_id} "$file"`;
		}
		
		$count++;
	}
			
	if ($count > 0) {
		print " * Loading CUFTS journals records\n";
		print `util/load_cufts_journals.pl --site_id=${site_id}`;
	} elsif (defined($site->rebuild_ejournals_only) && $site->rebuild_ejournals_only eq '1') {
		print " * Loading CUFTS journal records ONLY\n";
		print `util/load_cufts_journals.pl --site_id=${site_id} --clear`;
	}

	$site->rebuild_cjdb(undef);
	$site->rebuild_ejournals_only(undef);
	$site->update;
	$site->dbi_commit;

	print "Finished ", $site->name,  "\n";
}	
	


