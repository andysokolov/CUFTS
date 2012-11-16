#!/usr/local/bin/perl

##
## This script checks all CUFTS sites for files that are
## marked for reloading and then loads the print/CUFTS records
## if required.
##


$| = 1;

use Data::Dumper;

use lib qw(lib);

use CJDB::DB::DBI;
use CUFTS::DB::DBI;

use CUFTS::DB::Sites;
use CUFTS::DB::Resources;
use CUFTS::DB::Journals;
use CUFTS::DB::JournalsAuth;

use CUFTS::Util::Simple;

use Net::IP;

use Unicode::String qw(utf8 latin1);

use strict;

load_all_sites();

sub load_all_sites {
    my $output;
    $output .= qq{<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n};
    $output .= qq{<!DOCTYPE institutions PUBLIC "-//GOOGLE//Institutional Links List 1.0//EN" "http://scholar.google.com/scholar/institutions.dtd">\n};
    $output .= "<institutions>\n";

    my $site_iter = CUFTS::DB::Sites->retrieve_all;

SITE:
    while ( my $site = $site_iter->next ) {
    	print "Checking " . $site->name . "\n";

    	next if $site->google_scholar_on ne '1';
    	my $errors = 0;
    	if ( is_empty_string($site->google_scholar_e_link_label) ) {
    	    print " * Error: electronic link label field is empty\n";
    	    $errors++;
    	}
    	if ( is_empty_string($site->google_scholar_other_link_label) ) {
    	    print " * Error: other link label field is empty\n";
    	    $errors++;
    	}
    	if ( is_empty_string($site->google_scholar_openurl_base) ) {
    	    print " * Error: OpenURL base field is empty\n";
    	    $errors++;
    	}
    	if ( !scalar($site->ips) ) {
    	    print " * Error: No site IP ranges defined\n";
    	    $errors++;
    	}
    	
        next if $errors;

        $output .= load_site($site);

    	print "Finished ", $site->name,  "\n";
    }	
    $output .= "</institutions>\n";

    print "Attempting to create control file\n";

    my $dir = $CUFTS::Config::CUFTS_RESOLVER_SITE_DIR . '/static';
    -d $dir
        or mkdir $dir
            or die("Unable to create directory for Google Scholar control file ($dir): $!");

    $dir .= '/GoogleScholar';
    -d $dir
         or mkdir $dir
             or die("Unable to create directory for Google Scholar control file ($dir): $!");
            
    my $file = $dir . '/institutions.xml';
    open GSFILE, ">$file"
        or die("Unable to open file ($file) for writing: $!");
    
    print GSFILE $output;
    close GSFILE;

    print "Done!\n";
}

sub load_site {
    my ($site) = @_;

	my $site_id = $site->id;	

    my $lj_iter = CUFTS::DB::LocalJournals->search({
        'active'          => 't',
        'resource.active' => 't',
        'resource.site'   => $site_id,
    },
    );
    my %jas;
    my $count;
    while ( my $lj = $lj_iter->next ) {

        my $gj = $lj->journal;
        my $ft_start_date  = defined($lj->ft_start_date)  ? $lj->ft_start_date  : defined($gj) ? $gj->ft_start_date  : undef;
        my $ft_end_date    = defined($lj->ft_end_date)    ? $lj->ft_end_date    : defined($gj) ? $gj->ft_end_date    : undef;
        my $embargo_days   = defined($lj->embargo_days)   ? $lj->embargo_days   : defined($gj) ? $gj->embargo_days   : undef;
        my $embargo_months = defined($lj->embargo_months) ? $lj->embargo_months : defined($gj) ? $gj->embargo_months : undef;
        my $ja_id          = defined($lj->journal_auth)   ? $lj->journal_auth   : defined($gj) ? $gj->journal_auth   : undef;

        next if !defined($ja_id);

        next if    is_empty_string($ft_start_date  )
                && is_empty_string($ft_end_date    )
                && is_empty_string($embargo_days   )
                && is_empty_string($embargo_months );

        if ( !defined($ft_start_date) ) {
            $jas{$ja_id}->{start} = '0000-00-00';
        }
        elsif ( !defined($jas{$ja_id}->{start}) || $ft_start_date lt $jas{$ja_id}->{start} ) {
            $jas{$ja_id}->{start} = $ft_start_date;
        }

        if ( !defined($ft_end_date) || $ft_end_date eq '2038-12-31' ) {
            $jas{$ja_id}->{end} = '9999-99-99';
        }
        elsif ( !defined($jas{$ja_id}->{end}) || $ft_end_date gt $jas{$ja_id}->{end} ) {
            $jas{$ja_id}->{end} = $ft_end_date;
        }

        if ( not_empty_string($embargo_months) ) {
            $embargo_days = $embargo_months * 30;
        }
        if ( not_empty_string($embargo_days) ) {
            if ( !defined($jas{$ja_id}->{embargo}) || $embargo_days < $jas{$ja_id}->{embargo} ) {
                $jas{$ja_id}->{embargo} = $embargo_days;
            }
        } else {
            $jas{$ja_id}->{embargo} = 0;
        }
 
    }

    my $output;
    my $file_count = 0;

    foreach my $ja_id ( keys %jas ) {
        my $journal_auth = CUFTS::DB::JournalsAuth->retrieve($ja_id);
        next if !defined($journal_auth);
        $output .=  "<item type=\"electronic\">\n";
        my $title = latin1($journal_auth->title)->utf8;

        # Do this better.

        $title =~ s/&/&amp;/g;
        $title =~ s/</&lt;/g;
        $title =~ s/>/&gt;/g;

        $output .=  "<title>$title</title>\n";
        foreach my $issn ( map { $_->issn } $journal_auth->issns ) {
            substr($issn, 4, 0) = '-';
            $output .=  "<issn>$issn</issn>\n";
        }

        $output .=  "<coverage>\n";
        if ( $jas{$ja_id}->{start} ne '0000-00-00' ) {
            my ($year, $month, $day) = split '-', $jas{$ja_id}->{start};
            $output .=  "<from>\n";
            $output .=  "<year>$year</year>\n";
            $output .=  "<month>$month</month>\n";
            $output .=  "</from>\n";
        }

        if ( $jas{$ja_id}->{end} ne '9999-99-99' ) {
            my ($year, $month, $day) = split '-', $jas{$ja_id}->{end};
            $output .=  "<to>\n";
            $output .=  "<year>$year</year>\n";
            $output .=  "<month>$month</month>\n";
            $output .=  "</to>\n";
        }

        if ( not_empty_string($jas{$ja_id}->{embargo}) && $jas{$ja_id}->{embargo} > 0 ) {
            $output .=  "<embargo>\n";
            $output .=  "<days_not_available>" . $jas{$ja_id}->{embargo} ."</days_not_available>\n";
            $output .=  "</embargo>\n";
        }
        
        
        $output .=  "</coverage>\n";
        $output .=  "</item>\n";

        if ( length($output) > 1046528 ) {
            $file_count = output( $site, $file_count, \$output );
            $output = '';
        }

    }

    $file_count = output( $site, $file_count, \$output );

    return create_summary($site, $file_count);
}

sub create_summary {
    my ($site, $file_count) = @_;
    
    my $site_key = $site->key;
    my $site_id  = $site->id;
    
    my $output = qq{<institutional_links id="$site_key">\n};
    
    $output .= "<institution>" . $site->name . "</institution>\n";
    if ( not_empty_string($site->google_scholar_keywords) ) {
        $output .=  "<keywords>" . $site->google_scholar_keywords . "</keywords>\n";
    }
    $output .=  "<contact>" . $site->email . "</contact>\n";
    $output .=  "<electronic_link_label>" .  $site->google_scholar_e_link_label . "</electronic_link_label>\n";
    $output .=  "<other_link_label>" .  $site->google_scholar_other_link_label . "</other_link_label>\n";
    
    $output .=  "<openurl_base>" . $site->google_scholar_openurl_base . "</openurl_base>\n";
    
    $output .=  "<openurl_option>doi</openurl_option>\n";
    $output .=  "<openurl_option>journal-title</openurl_option>\n";
    $output .=  "<openurl_option>pmid</openurl_option>\n";

    $output .=  "<electronic_holdings>\n";
    foreach my $count ( 1 .. ( $file_count - 1 ) ) {
        $output .=  "<url>${CUFTS::Config::CUFTS_RESOLVER_URL}/sites/${site_id}/static/GoogleScholar/journals${count}.xml</url>\n";
    }
    $output .=  "</electronic_holdings>\n";
    
    foreach my $ip ( $site->ips ) {
        my $start = $ip->ip_low;
        my $end   = $ip->ip_high;
        $output .=  "<patron_ip_range>${start}-${end}</patron_ip_range>\n";
    }
    
    if ( not_empty_string($site->google_scholar_other_xml) ) {
        $output .= $site->google_scholar_other_xml;
    }
    
    $output .=  "</institutional_links>\n";

    return $output;
}


sub output {
    my ($site, $file_count, $output) = @_;

    if ( !defined($site) ) {
        die("No site defined in output()");
    }

    my $dir = $CUFTS::Config::CUFTS_RESOLVER_SITE_DIR;

    if ( $file_count == 0 ) {
        
        # First run - create directories if necessary, delete any
        # existing files.

        -d $dir
            or die("No directory for the CUFTS resolver site files: $dir");

        $dir .= '/' . $site->id;
        -d $dir
            or mkdir $dir
                or die("Unable to create directory $dir: $!");

        $dir .= '/static';
        -d $dir
            or mkdir $dir
                or die("Unable to create directory $dir: $!");

        $dir .= '/GoogleScholar';
        -d $dir
            or mkdir $dir
                or die("Unable to create directory $dir: $!");

        opendir GSDIR, $dir
            or die("Unable to open GS dir: $!");
            
        # Delete all files in GoogleScholar directory that do not start with '.'

        my @unlink_files = map { "$dir/$_" } grep !/^\./, readdir GSDIR;
        closedir GSDIR;
        my @unlink_errs = grep {not unlink} @unlink_files;
        if (@unlink_errs) {
            die("Unable to remove exising GS files: @unlink_errs\n")
        }

        $file_count++;
    } else {
        $dir .= '/' . $site->id . '/static/GoogleScholar';
    }

    my $file = "$dir/journals${file_count}.xml";
    open GSFILE, ">$file"
        or die("Unable to open file ($file) for writing: $!");

    print GSFILE qq{<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n};
    print GSFILE qq{<!DOCTYPE institutional_holdings PUBLIC "-//GOOGLE//Institutional Holdings 1.0//EN" "http://scholar.google.com/scholar/institutional_holdings.dtd">\n};
    print GSFILE "<institutional_holdings>\n" . $$output . "</institutional_holdings>\n";

    close GSFILE;
    $file_count++;

    return $file_count;
}
