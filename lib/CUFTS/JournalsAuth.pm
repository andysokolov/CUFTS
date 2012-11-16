package CUFTS::JournalsAuth;

# Utility code for working with JournalsAuth records

use CUFTS::Util::Simple;

use CUFTS::DB::Resources;
use CUFTS::DB::JournalsAuthTitles;
use CUFTS::DB::JournalsAuth;
use CUFTS::DB::Journals;
use CUFTS::DB::LocalJournals;
use CJDB::DB::Journals;
use CJDB::DB::Tags;

use String::Util qw(hascontent);

use strict;

##
## Link Journals to JournalAuth records or create new Journal Auth records
##

sub load_journals {
    my ( $flag, $timestamp, $site_id, $options ) = @_;

    my $stats = {};
    my $search_extra = {};
    my $search_module;
    
    my $searches = {
        issns => {
            issn         => { '!=' => undef },
            e_issn       => { '!=' => undef },
            journal_auth => undef,
            'resource.active' => 't',
        },
        issn => {
            issn         => { '!=' => undef },
            e_issn       => undef,
            journal_auth => undef,
            'resource.active' => 't',
        },
        e_issn => {
            issn         => undef,
            e_issn       => { '!=' => undef },
            journal_auth => undef,
            'resource.active' => 't',
        },
        no_issn => {
            issn              => undef,
            e_issn            => undef,
            journal_auth      => undef,
            'resource.active' => 't',
        },
    };

    # Add extra search information if we're doing a local resource build

    if ( $flag eq 'local' ) {

        $search_extra  = { journal => undef };
        $search_module = 'CUFTS::DB::LocalJournals';
        
        if ( $site_id ) {
            $search_extra->{'resource.site'} = $site_id;
        }

    }
    else {
        $search_module = 'CUFTS::DB::Journals';
    }

    $options->{progress} && print "\n-=- Processing journals with both ISSN and eISSNs -=-\n\n";

    my $journals = $search_module->search( { %{$searches->{issns}}, %{$search_extra} } );
    while ( my $journal = $journals->next ) {
        process_journal( $journal, $stats, $timestamp, $options->{term} );
#        last if $stats->{count} % 100 == 99;
    }

    $options->{progress} && print "\n\n-=- Processing journals with only ISSNs -=-\n\n";

    $journals = $search_module->search( { %{$searches->{issn}}, %{$search_extra} } );
    while ( my $journal = $journals->next ) {
        process_journal( $journal, $stats, $timestamp, $options->{term} );
#        last if $stats->{count} % 100 == 99;
    }

    $options->{progress} && print "\n-=- Processing journals with only eISSNs -=-\n\n";

    $journals = $search_module->search( { %{$searches->{e_issn}}, %{$search_extra} } );
    while ( my $journal = $journals->next ) {
        process_journal( $journal, $stats, $timestamp, $options->{term} );
#        last if $stats->{count} % 100 == 99;
    }

    $options->{progress} && print "\n-=- Processing journals with no ISSNs -=-\n\n";

    $journals = $search_module->search( { %{$searches->{no_issn}}, %{$search_extra} } );
    while ( my $journal = $journals->next ) {
        process_journal( $journal, $stats, $timestamp, $options->{term} );
#        last if $stats->{count} % 100 == 99;
    }
    
    return $stats;
}


sub process_journal {
    my ( $journal, $stats, $timestamp, $options ) = @_;

    # Skip journal if resource and journal is not active

    return undef if $journal->can('active') && !$journal->active;

    $stats->{count}++;

    # Find ISSN matches

    my @issn_search;

    if ( hascontent( $journal->issn ) ) {
        push @issn_search, $journal->issn;
    }
    if ( hascontent( $journal->e_issn ) && !grep { $_ eq $journal->e_issn } @issn_search ) {
        push @issn_search, $journal->e_issn;
    }

    my @journal_auths;
    my $journal_auth;

    if ( scalar(@issn_search) ) {
        @journal_auths = CUFTS::DB::JournalsAuth->search_by_issns(@issn_search);
    }
    else {
        @journal_auths = CUFTS::DB::JournalsAuth->search_by_exact_title_with_no_issns($journal->title);
    }

    if ( scalar(@journal_auths) > 1 ) {
        
        if (defined($options->{term})) {
            # Interactive
            # TODO: This should be pulled out and handled somewhere else.. it came from the original build_journals_auth.pl script
            
            display_journal($journal);
            foreach my $ja (@journal_auths) {
                display_journal_auth($ja);
            }
            
INPUT:
            while (1) {
                print "[S]kip record, [c]reate new journal_auth, [m]erge all journal_auths, or enter journal_auth ids.\n";
                my $input = $options->{term}->readline('[S/c/m/ids]: ');

                if ( $input =~ /^[cC]/ ) {
                    $journal_auth = create_ja_record($journal, \@issn_search, $timestamp, $stats);
                    last INPUT;
                } elsif ( $input =~ /^[mM]/ ) {
                    $journal_auth = CUFTS::JournalsAuth->merge( map {$_->id} @journal_auths );
                    last INPUT;
                } elsif ( $input =~ /^[sS]/ || $input eq '' ) {
                    return undef;
                } elsif ( $input =~ /^[\d ]+$/ ) {

                    my @merge_ids = split /\s+/, $input;
                    foreach my $merge_id (@merge_ids) {
                        $merge_id = int($merge_id);
                        if ( !grep { $merge_id == $_->id } @journal_auths ) {
                            print "id input does not match possible merge targets: $merge_id\n";
                            next INPUT;
                        }
                        $journal_auth = CUFTS::JournalsAuth->merge(@merge_ids);
                        last INPUT;
                    }

                }
            }
        }
        else {
            push @{$stats->{multiple_matches}}, $journal;
            $journal_auth = create_ja_record($journal, \@issn_search, $timestamp, $stats, $options);
            
        }
    }
    elsif ( scalar(@journal_auths) == 1 ) {
        $journal_auth = update_ja_record($journal_auths[0], $journal, \@issn_search, $timestamp, $stats, $options);
    }
    else {
        $journal_auth = create_ja_record($journal, \@issn_search, $timestamp, $stats, $options);
    }

    if ( $stats->{count} % 100 == 0 ) {
        if ( $options->{progress} ) {
            print "\n", $stats->{count}, "\n";
        }
        if ( $options->{checkpoint} ) {
            CUFTS::DB::DBI->dbi_commit();
        }
    }

    return $journal_auth;
}


sub display_journal {
    my ($journal) = @_;
    
    print "New journal record\n--------------\n";
    print $journal->title, "\n";
    if ($journal->issn) {
        print $journal->issn, "\n";
    }
    if ($journal->e_issn) {
        print $journal->e_issn, "\n";
    }
    print $journal->resource->name, ' - ', $journal->resource->provider, "\n";
    print "-------------------\n";
    
    return 1;
}

sub display_journal_auth {
    my ($ja) = @_;
    
    print "Existing JournalAuth record\n-------------------\n";
    print "ID: ", $ja->id, "\n";
    print $ja->title, "\n";
    if ($ja->issns) {
        print join ' ', map {$_->issn} $ja->issns;
    }
    foreach my $title ($ja->titles) {
        print $title, "\n";
    }
    print "-------------------\n";

    return 1;
}


sub create_ja_record {
    my ( $journal, $issns, $timestamp, $stats, $options ) = @_;

    my $title = trim_string($journal->title);
    
    # Test ISSNs
    foreach my $issn (@$issns) {
        my @issns = CUFTS::DB::JournalsAuthISSNs->search( { issn => $issn } );
        if ( scalar(@issns) ) {
            push @{$stats->{ issn_dupe }}, $journal;
            return undef;
        }
    }
    
    
    my $journal_auth = CUFTS::DB::JournalsAuth->create(
        {   
            title    => $title,
            created  => $timestamp,
            modified => $timestamp,
        }
    );

    CUFTS::DB::JournalsAuthTitles->create(
        {   
            'journal_auth' => $journal_auth->id,
            'title'        => $title,
            'title_count'  => 1
        }
    );

    $journal->journal_auth( $journal_auth->id );
    $journal->update;

    foreach my $issn (@$issns) {
        $journal_auth->add_to_issns(
            {
                issn => $issn,
                info => 'CUFTS (initial load)',
            }
        );
    }

    $stats->{new_record}++;

    $options->{progress} and print "!";
    
    return $journal_auth;
}

sub update_ja_record {
    my ( $journal_auth, $journal, $issns, $timestamp, $stats, $options ) = @_;

    my @journal_auth_issns = map { $_->issn } $journal_auth->issns;

    # Test ISSNs - don't create records with duplicate ISSNS and
    # don't naively merge records that already have two ISSNs 

    my $new_issn_count = 0;
    foreach my $issn (@$issns) {
        if ( !grep { $issn eq $_ } @journal_auth_issns ) {
        
            my @issns = CUFTS::DB::JournalsAuthISSNs->search( { issn => $issn } );
            if ( scalar(@issns) ) {
                push @{$stats->{ issn_dupe }}, $journal;
                return undef;
            }
            $new_issn_count++;

        }
    }

    if ($new_issn_count && ( $new_issn_count + scalar(@journal_auth_issns) ) > 2) {
        push @{$stats->{ too_many_issns }}, $journal;
        return undef;
    }
    
    $journal->journal_auth( $journal_auth->id );
    $journal->update;

    my $title = trim_string($journal->title);

    my $title_rec = CUFTS::DB::JournalsAuthTitles->find_or_create(
        {
            title        => $title,
            journal_auth => $journal_auth->id
        }
    );
    $title_rec->title_count( $title_rec->title_count + 1 );
    $title_rec->update;

    foreach my $issn (@$issns) {
        if ( !grep { $issn eq $_ } @journal_auth_issns ) {

            $journal_auth->add_to_issns(
                {
                    issn => $issn,
                    info => 'CUFTS (initial load)'
                }
            );

        }
    }

    $journal_auth->modified($timestamp);
    $journal_auth->update;
    
    $stats->{match}++;

    $options->{progress} and print "1";
    
    return $journal_auth;
}


##
## Handle merging Journal Auth records and the various attached pieces in the CJDB
##

sub merge {
    my ( $class, @ids ) = @_;

    return undef if !scalar(@ids);

    # Merge down to the first id passed in
    my $journal_auth = CUFTS::DB::JournalsAuth->retrieve( shift(@ids) );
    
    foreach my $ja_id (@ids) {

        my $old_journal_auth = CUFTS::DB::JournalsAuth->retrieve($ja_id);

        $class->merge_ja_issns(  $journal_auth, $old_journal_auth );
        $class->merge_ja_titles( $journal_auth, $old_journal_auth );

        $class->merge_cjdb_journals( $journal_auth, $old_journal_auth );
        $class->merge_cjdb_tags(     $journal_auth, $old_journal_auth );

        $class->update_journals( $journal_auth, $old_journal_auth );

        $old_journal_auth->delete();
    }

    return $journal_auth;
}

sub update_journals {
    my ( $class, $journal_auth, $old_journal_auth ) = @_;
    
    my @journals = CUFTS::DB::Journals->search( 'journal_auth' => $old_journal_auth->id );
    foreach my $journal ( @journals ) {
        $journal->journal_auth( $journal_auth->id );
        $journal->update();
    }

    @journals = CUFTS::DB::LocalJournals->search( 'journal_auth' => $old_journal_auth->id );
    foreach my $journal ( @journals ) {
        $journal->journal_auth( $journal_auth->id );
        $journal->update();
    }

    return 1;
}


sub merge_ja_issns {
    my ( $class, $journal_auth, $old_journal_auth ) = @_;

    foreach my $issn ( $old_journal_auth->issns ) {
        my $record = { journal_auth => $journal_auth->id, issn => $issn->issn };
        $issn->delete();
        if ( !CUFTS::DB::JournalsAuthISSNs->search($record)->first ) {
            CUFTS::DB::JournalsAuthISSNs->create($record);
        }
    }

    return 1;
}

sub merge_ja_titles {
    my ( $class, $journal_auth, $old_journal_auth ) = @_;

    foreach my $title ( $old_journal_auth->titles ) {

        my $record = { journal_auth => $journal_auth->id, };
        foreach my $column ( $title->columns ) {
            next if grep { $_ eq $column } qw{ id journal_auth };
            $record->{$column} = $title->$column();
        }

        my $existing = CUFTS::DB::JournalsAuthTitles->search(
            {   journal_auth => $record->{journal_auth},
                title        => $record->{title},
            }
        )->first;

        if ($existing) {
            $existing->title_count($existing->title_count() + $record->{title_count});
            $existing->update;
        }
        else {
            CUFTS::DB::JournalsAuthTitles->create($record);
        }

        $title->delete();
    }

    return 1;
}

sub merge_cjdb_journals {
    my ( $class, $journal_auth, $old_journal_auth ) = @_;

    my $site_iter = CUFTS::DB::Sites->retrieve_all();
    while ( my $site = $site_iter->next ) {

        my $cjdb_journal = CJDB::DB::Journals->search(
            {
                site         => $site->id,
                journals_auth => $old_journal_auth->id,
            }
        )->first;
        
        my $old_cjdb_journals_iter = CJDB::DB::Journals->search(
            {
                site         => $site->id,
                journals_auth => $journal_auth->id,
            }
        );
        
        while ( my $old_cjdb_journal = $old_cjdb_journals_iter->next ) {

            if ( defined($cjdb_journal) ) {
                $class->merge_cjdb_titles(       $cjdb_journal, $old_cjdb_journal );
                $class->merge_cjdb_links(        $cjdb_journal, $old_cjdb_journal );
                $class->merge_cjdb_subjects(     $cjdb_journal, $old_cjdb_journal );
                $class->merge_cjdb_issns(        $cjdb_journal, $old_cjdb_journal );
                $class->merge_cjdb_associations( $cjdb_journal, $old_cjdb_journal );
                $class->merge_cjdb_relations(    $cjdb_journal, $old_cjdb_journal );
                
                $old_cjdb_journal->delete();
            }
            else {
                $old_cjdb_journal->journals_auth( $journal_auth->id );
                $old_cjdb_journal->update();

            }
        }
    }

    return 1;
}

sub merge_cjdb_titles {
    my ( $class, $cjdb_journal, $old_cjdb_journal ) = @_;

    my @titles = map { $_->id } $cjdb_journal->titles;

    foreach my $journaltitle ( CJDB::DB::JournalsTitles->search( journal => $old_cjdb_journal->id ) ) {

        my $title_id = $journaltitle->title->id;

        if ( grep { $title_id eq $_ } @titles ) {
            $journaltitle->delete();
        }
        else {
            $journaltitle->journal( $cjdb_journal->id );
            $journaltitle->update;
        }

    }

    return 1;
}

sub merge_cjdb_links {
    my ( $class, $cjdb_journal, $old_cjdb_journal ) = @_;

    my @links = map { $_->url } $cjdb_journal->links;
    foreach my $link ($old_cjdb_journal->links) {

        if ( grep { $link->url eq $_ } @links ) {
            $link->delete();
        }
        else {
            $link->journal( $cjdb_journal->id );
            $link->update;
        }
        
    }
    
    return 1;
}


sub merge_cjdb_associations {
    my ( $class, $cjdb_journal, $old_cjdb_journal ) = @_;

    my @associations = map { $_->id } $cjdb_journal->associations;
    foreach my $journalassociation ( CJDB::DB::JournalsAssociations->search( journal => $old_cjdb_journal->id ) ) {

        my $association_id = $journalassociation->association->id;

        if ( grep { $association_id eq $_ } @associations ) {
            $journalassociation->delete();
        }
        else {
            $journalassociation->journal( $cjdb_journal->id );
            $journalassociation->update;
        }
        
    }
    
    return 1;
}

sub merge_cjdb_subjects {
    my ( $class, $cjdb_journal, $old_cjdb_journal ) = @_;

    my @subjects = map { $_->id } $cjdb_journal->subjects;
    foreach my $journalsubject ( CJDB::DB::JournalsSubjects->search( journal => $old_cjdb_journal->id ) ) {

        my $subject_id = $journalsubject->subject->id;

        if ( grep { $subject_id eq $_ } @subjects ) {
            $journalsubject->delete();
        }
        else {
            $journalsubject->journal( $cjdb_journal->id );
            $journalsubject->update;
        }
        
    }
    
    return 1;
}


sub merge_cjdb_relations {
    my ( $class, $cjdb_journal, $old_cjdb_journal ) = @_;

    my @relations = map { $_->title } $cjdb_journal->relations;
    foreach my $relation ($old_cjdb_journal->relations) {

        if ( grep { $relation->title eq $_ } @relations ) {
            $relation->delete();
        }
        else {
            $relation->journal( $cjdb_journal->id );
            $relation->update;
        }
        
    }
    
    return 1;
}


sub merge_cjdb_issns {
    my ( $class, $cjdb_journal, $old_cjdb_journal ) = @_;

    my @issns = map { $_->issn } $cjdb_journal->issns;
    foreach my $issn ($old_cjdb_journal->issns) {

        if ( grep { $issn->issn eq $_ } @issns ) {
            $issn->delete();
        }
        else {
            $issn->journal( $cjdb_journal->id );
            $issn->update;
        }
        
    }
    
    return 1;
}


sub merge_cjdb_tags {
    my ( $class, $journal_auth, $old_journal_auth ) = @_;
    
    my $tags_iter = CJDB::DB::Tags->search({ journals_auth => $old_journal_auth->id });
    while (my $tag = $tags_iter->next) {
        # Check for existing tag on new journal
        my @existing = CJDB::DB::Tags->search(
            {
                tag          => $tag->tag,
                account      => $tag->account,
                journals_auth => $journal_auth->id,
            }
        );

        if ( scalar(@existing) ) {
            $tag->delete;
        }
        else {
            $tag->journals_auth( $journal_auth->id );
            $tag->update;
        } 
    }
    
    return 1;    
}


1;
