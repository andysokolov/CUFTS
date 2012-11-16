#!/usr/local/bin/perl

use lib qw(lib);

$| = 1;

my $PROGRESS = 1;
my $CHECKPOINT = 1;

use strict;

use Data::Dumper;

use CUFTS::Config;
use CUFTS::Util::Simple;

use CUFTS::DB::LocalJournals;
use CUFTS::DB::Journals;
use CUFTS::DB::JournalsAuthTitles;
use CUFTS::DB::JournalsAuth;
use CUFTS::JournalsAuth;

use Getopt::Long;
use MARC::Record;
use MARC::Field;
use MARC::File::USMARC;
use Term::ReadLine;

main();

sub main {
    my $timestamp = CUFTS::DB::DBI->get_now();

    # Read command line arguments
    my %options;
    GetOptions( \%options, 'report', 'local', 'interactive', 'site_key=s', 'site_id=i' );

    $options{progress}   = 1;
    $options{checkpoint} = 1;

    if ($options{interactive}) {
       $options{term} = new Term::ReadLine 'CUFTS Installation';
    }

    my $stats;
    if ( $options{local} ) {
        my $site_id = get_site_id(\%options);
        $stats = CUFTS::JournalsAuth::load_journals( 'local', $timestamp, $site_id, \%options );
    }
    else {
        $stats = CUFTS::JournalsAuth::load_journals( 'global', $timestamp, \%options );
    }

    CUFTS::DB::DBI->dbi_commit();
    
    display_stats($stats);

    return 1;
}

sub show_report {
    # slow, but easy
    
    my $journal_auths = CUFTS::DB::JournalsAuth->retrieve_all;
    while (my $journal_auth = $journal_auths->next) {
        my @titles = $journal_auth->titles;
        next if scalar(@titles) == 1;
        
        my @issns = $journal_auth->issns;
        my $issn_string = join ',', map {substr($_->issn,0,4) . '-' . substr($_->issn,4)} @issns;

        print $issn_string, "\n";
        foreach my $title (@titles) {
            print $title->title, "\n";
        }
        print "\n";
    }
}

sub get_site_id {
    my ( $options ) = @_;
    
    return $options->{site_id} if defined($options->{site_id});
    return undef if !defined($options->{site_key});

    my @sites = CUFTS::DB::Sites->search( key => $options->{site_key} );
    
    scalar(@sites) == 1 or
        die('Could not get CUFTS site for key: ' . $options->{site_key} );
        
    return $sites[0]->id;
}

sub display_stats {
    my ($stats) = @_;
    
    print "\nJournal records checked: ", $stats->{count}, "\n";
    print "journal_auth records created: ", $stats->{new_record}, "\n";
    print "journal_auth records matched: ", $stats->{match}, "\n";
    
    print "Records skipped due to existing ISSNs\n------------------------------------\n";
    foreach my $journal ( @{$stats->{issn_dupe}} ) {
        print $journal->title, "\t";
        print $journal->issn, "\t";
        print $journal->e_issn, "\t";
        print $journal->resource->name, "\n";
    }
    
    print "Records skipped due to multiple matches\n------------------------------------\n";
    foreach my $journal ( @{$stats->{multiple_matches}} ) {
        print $journal->title, "\t";
        print $journal->issn, "\t";
        print $journal->e_issn, "\t";
        print $journal->resource->name, "\n";
    }

    print "Records skipped due to merge creating too many ISSNs\n------------------------------------\n";
    foreach my $journal ( @{$stats->{too_many_issns}} ) {
        print $journal->title, "\t";
        print $journal->issn, "\t";
        print $journal->e_issn, "\t";
        print $journal->resource->name, "\n";
    }

    return 1;
}