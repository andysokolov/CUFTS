#!/usr/local/bin/perl

use strict;

use lib 'lib';

use CUFTS::DB::Sites;
use CUFTS::DB::JournalsAuth;
use CUFTS::CJDB::Util;
use Data::Dumper;

use Getopt::Long;

my %options;
GetOptions(\%options, 'site_key=s', 'site_id=i', 'append', 'module=s');
my @files = @ARGV;

# Check for necessary arguments

if (!scalar(@files) || (!defined($options{'site_key'}) && !defined($options{'site_id'}))) {
	usage();
	exit;
}

# Get CUFTS site id

my $site = get_site();   
defined($site) or 
	die("Unable to retrieve site.");

my $site_id = $site->id;
my $site_key = $site->key;

# Create customized loader object
	
my $loader = load_module($site_key);
$loader->site_id($site_id);

my $batch = $loader->get_batch(@files);
$batch->strict_off;

my %stats;

while (my $record = $batch->next()) {
	$stats{total}++;

	my @issns = $loader->get_issns($record);
	my $title = $loader->get_title($record);

	# Remove duplicate ISSNs
	
	my %temp_issns = map {$_,1} @issns;
	@issns = keys(%temp_issns);

	if (scalar(@issns) > 1) {
		print "Trimming multiple ISSNs\n";
		print "Original ISSN list: ", (join ',', @issns), "\n";

		# Try removing possible 78.x related ISSNs to avoid multiple matches
		
		my @seveneight_fields = $loader->get_ceding_fields_issns($record);

		print "78. ISSNs: ", (join ',', @seveneight_fields), "\n";
		
		my @temp_issns;
		foreach my $issn (@issns) {
			if (!grep {$_ eq $issn} @seveneight_fields) {
				push @temp_issns, $issn;
			}
		}
		
		# Only use this new issn array if we haven't gotten rid of all the ISSNs
		
		scalar(@temp_issns) and
			@issns = @temp_issns;

		print "Final ISSN list: ", (join ',', @issns), "\n";
	}
	

	if (scalar(@issns)) {

		my @journals_auths = CUFTS::DB::JournalsAuth->search_by_issns(@issns);
	
		if (scalar(@journals_auths) > 1) {
			
			# Attempt title match

			my $title_ranks = rank_titles($record, $title, \@journals_auths);

			print join ',', @$title_ranks;
			print "\n";

			my ($max, $max_count, $index) = (0, 0, -1);
			my $max_count = 0;
			foreach my $x (0 .. $#$title_ranks) {
				if ($title_ranks->[$x] > $max) {
					$max = $title_ranks->[$x];
					$index = $x;
					$max_count = 1;
				} elsif ($title_ranks->[$x] == $max) {
					$max_count++;
				}
			}
			
			if ($max_count == 1) {
				$stats{title_shootout_won}++;
			} else {
				$stats{title_shootout_ambiguous}++;
			}

			next;

		} elsif (scalar(@journals_auths) == 1) {
			$stats{single_issn_journal_auth_match}++;
			next;
		}
	}
			
	# Exact title main match

	my @journals_auths = CUFTS::DB::JournalsAuth->search_by_title($title);
	if (scalar(@journals_auths) > 1) {
		$stats{multiple_main_title_matches}++;
	} elsif (scalar(@journals_auths) == 1) {
		$stats{single_main_title_match}++;
	} else {

		# Alternate title matches

		foreach my $title_arr ($loader->get_alt_titles($record), [$loader->strip_title($loader->get_sort_title($record)), $loader->get_sort_title($record)]) {
			my $alt_title = $title_arr->[1];
			my @temp_journals_auth = CUFTS::DB::JournalsAuth->search_by_title($alt_title);
			foreach my $temp_journal (@temp_journals_auth) {
				grep {$_->id == $temp_journal->id} @journals_auths or
					push @journals_auths, $temp_journal;
			}
		}
		if (scalar(@journals_auths) > 1) {
			$stats{multiple_alt_titles_match}++;
		} elsif (scalar(@journals_auths) == 1) {
			$stats{single_alt_titles_match}++;
		} else {
			if (scalar(@issns)) {
				$stats{no_match_have_issn}++;
			} else {
				$stats{no_match_no_issn}++;
			}
		}
	}
}
	
print "\n", Dumper(\%stats), "\n";

sub rank_titles {
	my ($record, $print_title, $journals_auths) = @_;

	$print_title = lc($print_title);
	$print_title =~ s/^\s+//;
	$print_title =~ s/\s+$//;

	my $stripped_print_title = CUFTS::CJDB::Util::strip_title_for_matching(CUFTS::CJDB::Util::strip_title($print_title));
	$stripped_print_title =~ tr/a-z0-9 //cd;


	my @alt_titles = $loader->get_alt_titles($record);

	print "-------------- TITLE SHOOTOUT! ------------\n";

	print "Print title: $print_title\n";
	print "Stripped print title: $stripped_print_title\n";
	foreach my $title_arr (@alt_titles) {
		print "Alt title: ", $title_arr->[1], "\n";
	}

	print "\n\n";

	my @ranks;
	foreach my $x (0 .. $#$journals_auths) {
		my $journals_auth = $journals_auths->[$x];

		print "===\n";
		print "J_A: ", $journals_auth->title, "   ", (join ',', map {$_->issn} $journals_auth->issns), "\n";
		foreach my $jatitle ($journals_auth->titles) {
			print "J_A alt title: ", $jatitle->title, "\n";		
		}
		
		$ranks[$x] = compare_titles($journals_auth->title, $print_title);
		if ($ranks[$x] < 50) {
			foreach my $title ($journals_auth->titles) {
				my $new_rank = (compare_titles($title->title, $print_title) / 2) + 1;
				$new_rank > $ranks[$x] and
					$ranks[$x] = $new_rank;		
			}
		}

#		foreach my $title_arr (@alt_titles) {
#			my $alt_title = lc($title_arr->[1]);
#			foreach my $title ($journals_auth->titles) {
#				if (lc($title->title) eq $alt_title) {
#					$ranks[$x] += 1;
#				}
#			}
#		}

	}

	print "-------------------------------------------\n";
	
	return \@ranks;
}


sub compare_titles {
	my ($title1, $title2) = (lc(shift), lc(shift));
	
	my $stripped_title1 = CUFTS::CJDB::Util::strip_title_for_matching(CUFTS::CJDB::Util::strip_title($title1));
	my $stripped_title2 = CUFTS::CJDB::Util::strip_title_for_matching(CUFTS::CJDB::Util::strip_title($title2));

	$stripped_title1 =~ tr/a-z0-9 //cd;
	$stripped_title2 =~ tr/a-z0-9 //cd;

	print "stripped_title1: $stripped_title1\nstripped_title2: $stripped_title2\n\n";
	
	if ($title1 eq $title2) {
		return 100;
	} elsif ($stripped_title1 eq $stripped_title2) {
		return 75;
	} elsif (compare_title_words($stripped_title1, $stripped_title2)) {
		return 50;
	} elsif (CUFTS::CJDB::Util::title_match([$stripped_title1],[$stripped_title2])) {
		return 25;
	}
	
	return 0;
}

# Checks if titles contain all the same words, but in a different order

sub compare_title_words {
	my ($title1, $title2) = @_;
	my (%title1, %title2);
	
	foreach my $word (split / /, $title1) {
		$title1{$word}++;
	}

	foreach my $word (split / /, $title2) {
		$title2{$word}++;
	}

	foreach my $key (keys %title1) {
		if ($title1{$key} == $title2{$key}) {
			delete $title1{$key};
			delete $title2{$key};
		} else {
			return 0;
		}
	}

	if (scalar(keys(%title1)) == 0 && scalar(keys(%title2)) == 0) {
		return 1;
	} else {
		return 0;
	}

}


sub load_module {
	my ($site_key) = @_;

	my $module_name = 'CUFTS::CJDB::Loader::MARC::';
	if ($options{'module'}) {
		$module_name .= $options{'module'};
	} elsif (defined($site_key)) {
		$module_name .= $site_key;
	} else {
		die("Unable to determine module name");
	}

	eval "require $module_name";
	if ($@) {
		die("Unable to require $module_name: $@");
	}
	
	my $module = $module_name->new;
	defined($module) or
		die("Failed to create new loading object from module: $module_name");
		
	return $module;
}



sub get_site {
	# Try site_id

	defined($options{'site_id'}) and
		return CUFTS::DB::Sites->retrieve($options{'site_id'});


	defined($options{'site_key'}) or
		return undef;

	# Try site_key

	my @sites = CUFTS::DB::Sites->search('key' => $options{'site_key'});
	
	scalar(@sites) == 1 or
		die('Could not get CUFTS site for key: ' . $options{'site_key'});
		
	return $sites[0];
}
