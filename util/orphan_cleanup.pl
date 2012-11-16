# Finds and cleans up orphaned records that are no longer linked to anything

use Data::Dumper;

use lib qw(lib);

use CJDB::DB::DBI;
use CUFTS::DB::DBI;

use CUFTS::DB::Resources;
use CUFTS::DB::Journals;
use CUFTS::DB::JournalsAuth;

use CJDB::DB::Journals;
use CJDB::DB::Tags;

use Getopt::Long;
use Log::Log4perl qw(:easy);


my %options;
GetOptions( \%options, 'save', 'all', 'unlinked_jas', 'journal_links', 'orphaned_titles', 'orphaned_issns' );

Log::Log4perl->easy_init($INFO);
my $logger = Log::Log4perl->get_logger();

if ( $options{all} ) {
    unlinked_journal_auth();
    fix_journal_links();
    orphaned_issns();
    orphaned_titles();
}
else {
    if ( $options{unlinked_jas} ) {
        unlinked_journal_auth();
    }
    if ( $options{journal_links} ) {
        fix_journal_links();
    }
    if ( $options{orphaned_titles} ) {
        orphaned_issns();
    }
    if ( $options{orphaned_issns} ) {
        orphaned_titles();
    }
}


sub unlinked_journal_auth {
    $logger->info('Looking for Journal Auth records that are not linked to anything.');
    my $ja_iter = CUFTS::DB::JournalsAuth->retrieve_all();
    my $remove_count = 0;
    while ( my $ja = $ja_iter->next ) {
        my $ja_id = $ja->id;

        # Check for links to journals and local_journals

        my $count = CUFTS::DB::Journals->count_search({ journal_auth => $ja_id });
        next if $count;

        $count = CUFTS::DB::LocalJournals->count_search({ journal_auth => $ja_id });
        next if $count;

        $count = CJDB::DB::Journals->count_search({ journals_auth => $ja_id });
        next if $count;

        $count = CJDB::DB::Tags->count_search({ journals_auth => $ja_id });
        next if $count;

        if ( $options{save} ) {
            $logger->info('Deleting: ', $ja->title, ' (', $ja_id, ')' );
            CUFTS::DB::JournalsAuthTitles->search({ journal_auth => $ja_id })->delete_all;
            CUFTS::DB::JournalsAuthISSNs->search({ journal_auth => $ja_id })->delete_all;
            $ja->delete;
        }
        else {
            $logger->info('Found: ', $ja->title, ' (', $ja_id, ')' );
        }

        $remove_count++;
    }

    $logger->info('Total of ', $remove_count, ' unused journal authority records found.');

    if ( $options{save} ) {
        CUFTS::DB::DBI->dbi_commit();
    }
}

sub fix_journal_links {
    $logger->info('Looking for journal links to Journal Auth records that no longer exist.');
    my $journal_iter = CUFTS::DB::Journals->search({ journal_auth => { '!=' => undef } });
    $remove_count = 0;
    while ( my $journal = $journal_iter->next ) {
        my $ja = $journal->journal_auth;
        next if !defined($ja);
        next if defined($ja) && defined($ja->id) && defined($ja->title);

        if ( $options{save} ) {
            $logger->info('Clearing link: ', $journal->title, ' (', $journal->id, ') to journal_auth id: ', $ja_id );
            $journal->journal_auth(undef);
            $journal->update;
        }
        else {
            $logger->info('Found: ', $journal->title, ' (', $journal->id, ') to journal_auth id: ', $ja_id );
        }

        $remove_count++;
    }

    $logger->info('Total of ', $remove_count, ' links to missing journal authority records found.');
    if ( $options{save} ) {
        CUFTS::DB::DBI->dbi_commit();
    }
}

sub orphaned_issns {
    $logger->info('Looking for JournalAuthISSNs that no longer have a matching JournalAuth record.');
    my $issn_iter = CUFTS::DB::JournalsAuthISSNs->search();
    while ( my $issn = $issn_iter->next ) {
        my $ja = $issn->journal_auth;
        next if defined($ja) && defined($ja->id) && defined($ja->title);
        if ( $options{save} ) {
            $logger->info("Deleting an ISSN attached to a missing record. ISSN id: " . $issn->issn . ', journal auth id: ' . $issn->journal_auth );
            $issn->delete();
        }
        else {
            $logger->info("Found an ISSN attached to a missing record. ISSN id: " . $issn->issn . ', journal auth id: ' . $issn->journal_auth );
        }
    }
    if ( $options{save} ) {
        CUFTS::DB::DBI->dbi_commit();
    }
}

sub orphaned_titles {
    $logger->info('Looking for JournalAuthTitles that no longer have a matching JournalAuth record.');
    my $title_iter = CUFTS::DB::JournalsAuthTitles->search();
    while ( my $title = $title_iter->next ) {
        my $ja = $title->journal_auth;
        next if defined($ja) && defined($ja->id) && defined($ja->title);
        if ( $options{save} ) {
            $logger->info("Deleting a title attached to a missing record. Title id: " . $title->title . ', journal auth id: ' . $title->journal_auth );
            $title->delete();
        }
        else {
            $logger->info("Found a title attached to a missing record. Title id: " . $title->title . ', journal auth id: ' . $title->journal_auth );
        }
    }
    if ( $options{save} ) {
        CUFTS::DB::DBI->dbi_commit();
    }
}
