# Finds and cleans up orphaned records that are no longer linked to anything

use Data::Dumper;

use lib qw(lib);

use CUFTS::Config;

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
        orphaned_titles();
    }
    if ( $options{orphaned_issns} ) {
        orphaned_issns();
    }
}


sub unlinked_journal_auth {

    $logger->info('Looking for Journal Auth records that are not linked to anything.');

    my $schema = CUFTS::Config::get_schema();
    $schema->txn_begin if $options{save};

    my $ja_rs = $schema->resultset('JournalsAuth');

    my $remove_count = 0;
    while ( my $ja = $ja_rs->next ) {
        my $ja_id = $ja->id;

        # Check for links to journals and local_journals

        next if $ja->global_journals->count();
        next if $ja->local_journals->count();

        next if $ja->cjdb_journals->count();
        next if $ja->cjdb_tags->count();

        next if $ja->erm_mains->count();
        next if $ja->erm_counter_titles->count();

        if ( $options{save} ) {
            $logger->info('Deleting: ', $ja->title, ' (', $ja_id, ')' );
            $ja->titles->delete_all();
            $ja->issns->delete_all();
            $ja->delete;
        }
        else {
            $logger->info('Found: ', $ja->title, ' (', $ja_id, ')' );
        }

        $remove_count++;
    }

    $logger->info('Total of ', $remove_count, ' unused journal authority records found.');

    $schema->txn_commit if $options{save};
}

sub fix_journal_links {
    $logger->info('Looking for journal links to Journal Auth records that no longer exist.');

    my $schema = CUFTS::Config::get_schema();
    $schema->txn_begin if $options{save};

    my $journal_rs = $schema->resultset('GlobalJournals')->search({ 'me.journal_auth' => { '!=' => undef }, 'journal_auth.id' => undef }, { join => 'journal_auth' });
    $remove_count = 0;
    while ( my $journal = $journal_rs->next ) {
        if ( $options{save} ) {
            $logger->info('Clearing link: ', $journal->title, ' (', $journal->id, ') to journal_auth id: ', $journal->get_column('journal_auth') );
            $journal->update({ journal_auth => undef });
        }
        else {
            $logger->info('Found: ', $journal->title, ' (', $journal->id, ') to journal_auth id: ', $journal->get_column('journal_auth') );
        }

        $remove_count++;
    }

    $logger->info('Total of ', $remove_count, ' links to missing journal authority records found.');
    $schema->txn_commit if $options{save};
}

sub orphaned_issns {
    $logger->info('Looking for JournalAuthISSNs that no longer have a matching JournalAuth record.');

    my $schema = CUFTS::Config::get_schema();
    $schema->txn_begin if $options{save};

    my $issn_rs = $schema->resultset('JournalsAuthISSNs')->search({ 'journal_auth_left.id' => undef }, { join => 'journal_auth_left'} );
    while ( my $issn = $issn_rs->next ) {
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

    $schema->txn_commit if $options{save};
}

sub orphaned_titles {
    $logger->info('Looking for JournalAuthTitles that no longer have a matching JournalAuth record.');

    my $schema = CUFTS::Config::get_schema();
    $schema->txn_begin if $options{save};

    my $title_rs = $schema->resultset('JournalsAuthTitles')->search({ 'journal_auth_left.id' => undef }, { join => 'journal_auth_left'} );
    while ( my $title = $title_rs->next ) {
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

    $schema->txn_commit if $options{save};
}
