#!/usr/local/bin/perl

use lib qw(lib);

$| = 1;

my $PROGRESS = 1;
my $CHECKPOINT = 1;

use strict;

use Data::Dumper;

use CUFTS::Config;
use CUFTS::Util::Simple;

use CUFTS::JournalsAuth;

use Getopt::Long;
use MARC::Record;
use MARC::Field;
use MARC::File::USMARC;
use Term::ReadLine;

main();

sub main {
    my $schema = CUFTS::Config::get_schema();

    my $timestamp = $schema->get_now;

    # Read command line arguments
    my %options;
    GetOptions( \%options, 'report', 'local', 'interactive', 'site_key=s', 'site_id=i' );

    $options{progress}   = $PROGRESS;
    $options{checkpoint} = $CHECKPOINT;

    if ($options{interactive}) {
       $options{term} = new Term::ReadLine 'CUFTS Installation';
    }

    $schema->txn_begin();

    my $stats;
    if ( $options{local} ) {
        my $site_id = get_site_id($schema, \%options);
        $stats = CUFTS::JournalsAuth::load_journals( $schema, 'local', $timestamp, $site_id, \%options );
    }
    else {
        $stats = CUFTS::JournalsAuth::load_journals( $schema, 'global', $timestamp, \%options );
    }

    $schema->txn_commit();

    display_stats($stats);
}

sub get_site_id {
    my ( $schema, $options ) = @_;

    return $options->{site_id} if defined $options->{site_id};
    return undef if !defined $options->{site_key};

    my $site = CUFTS::DB::Sites->search({ key => $options->{site_key} })->first;

    return $site->id if defined $site;

    die('Unable to find site id.');
}

sub display_stats {
    my ($stats) = @_;

    print "\nJournal records checked: ", $stats->{count}, "\n";
    print "journal_auth records created: ", $stats->{new_record}, "\n";
    print "journal_auth records matched: ", $stats->{match}, "\n";

    print "Records skipped due to existing ISSNs\n------------------------------------\n";
    foreach my $journal ( @{$stats->{issn_dupe}} ) {
        display_journal_stats($journal);
    }

    print "Records skipped due to multiple matches\n------------------------------------\n";
    foreach my $journal ( @{$stats->{multiple_matches}} ) {
        display_journal_stats($journal);
    }

    print "Records skipped due to merge creating too many ISSNs\n------------------------------------\n";
    foreach my $journal ( @{$stats->{too_many_issns}} ) {
        display_journal_stats($journal);
    }

    return 1;
}

sub display_journal_stats {
    my $journal = shift;
    print $journal->{title}, "\t";
    print $journal->{issn}, "\t";
    print $journal->{e_issn}, "\t";
    print $journal->{resource}, "\n";
}