package CUFTS::JournalsAuth;

# Utility code for working with JournalsAuth records

# use CUFTS::Util::Simple;

use String::Util qw(hascontent trim);

use strict;

##
## Link Journals to JournalAuth records or create new Journal Auth records
##

sub load_journals {
    my ( $schema, $flag, $timestamp, $site_id, $options ) = @_;

    my $stats = {};
    my $main_rs;

    my $searches = {
        issns => {
            issn              => { '!=' => undef },
            e_issn            => { '!=' => undef },
            journal_auth      => undef,
        },
        issn => {
            issn              => { '!=' => undef },
            e_issn            => undef,
            journal_auth      => undef,
        },
        e_issn => {
            issn              => undef,
            e_issn            => { '!=' => undef },
            journal_auth      => undef,
        },
        no_issn => {
            issn              => undef,
            e_issn            => undef,
            journal_auth      => undef,
        },
    };

    # Add extra search information if we're doing a local resource build

    if ( $flag eq 'local' ) {
        $main_rs = $schema->resultset('LocalJournals')->search( { 'local_resource.active' => 't', journal => undef }, { join => 'local_resource' } );
        $main_rs = $main_rs->search({ 'local_resource.site' => $site_id }) if $site_id;
    }
    else {
        $main_rs = $schema->resultset('GlobalJournals')->search( { 'global_resource.active' => 't' }, { join => 'global_resource' } );
    }

    $options->{progress} && print "\n-=- Processing journals with both ISSN and eISSNs -=-\n\n";

    my $journals_rs = $main_rs->search( $searches->{issns} );
    while ( my $journal = $journals_rs->next ) {
        process_journal( $schema, $journal, $stats, $timestamp, $options );
#        last if $stats->{count} % 100 == 99;
    }

    $options->{progress} && print "\n\n-=- Processing journals with only ISSNs -=-\n\n";

    $journals_rs = $main_rs->search( $searches->{issn} );
    while ( my $journal = $journals_rs->next ) {
        process_journal( $schema, $journal, $stats, $timestamp, $options );
#        last if $stats->{count} % 100 == 99;
    }

    $options->{progress} && print "\n-=- Processing journals with only eISSNs -=-\n\n";

    $journals_rs = $main_rs->search( $searches->{e_issn} );
    while ( my $journal = $journals_rs->next ) {
        process_journal( $schema, $journal, $stats, $timestamp, $options );
#        last if $stats->{count} % 100 == 99;
    }

    $options->{progress} && print "\n-=- Processing journals with no ISSNs -=-\n\n";

    $journals_rs = $main_rs->search( $searches->{no_issn} );
    while ( my $journal = $journals_rs->next ) {
        process_journal( $schema, $journal, $stats, $timestamp, $options );
#        last if $stats->{count} % 100 == 99;
    }

    return $stats;
}


sub process_journal {
    my ( $schema, $journal, $stats, $timestamp, $options ) = @_;

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
        @journal_auths = $schema->resultset('JournalsAuth')->search_by_issns(@issn_search)->all;
    }
    else {
        @journal_auths = $schema->resultset('JournalsAuth')->search_by_exact_title_with_no_issns($journal->title);
    }

    if ( scalar @journal_auths > 1 ) {

        if ( defined $options->{term} ) {
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
            push @{$stats->{multiple_matches}}, flatten_for_stats($journal);
            $journal_auth = create_ja_record($schema, $journal, \@issn_search, $timestamp, $stats, $options);
        }
    }
    elsif ( scalar @journal_auths == 1 ) {
        $journal_auth = update_ja_record($schema, $journal_auths[0], $journal, \@issn_search, $timestamp, $stats, $options);
    }
    else {
        $journal_auth = create_ja_record($schema, $journal, \@issn_search, $timestamp, $stats, $options);
    }

    if ( $stats->{count} % 100 == 0 ) {
        if ( $options->{progress} ) {
            print "\n", $stats->{count}, "\n";
        }

        $schema->txn_commit() if $options->{checkpoint};
    }

    return $journal_auth;
}

sub flatten_for_stats {
    my ($journal) = @_;

    return {
        title    => $journal->title,
        issn     => $journal->issn,
        e_issn   => $journal->e_issn,
        resource => $journal->can('local_resource') ? $journal->local_resource->name : $journal->global_resource->name,
    };
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
    my ( $schema, $journal, $issns, $timestamp, $stats, $options ) = @_;

    my $title = trim($journal->title);

    # Test ISSNs
    foreach my $issn (@$issns) {
        my @issns = $schema->resultset('JournalsAuthISSNs')->search({ issn => $issn })->all;
        if ( scalar @issns ) {
            push @{$stats->{ issn_dupe }}, flatten_for_stats($journal);
            return undef;
        }
    }

    my $journal_auth = $schema->resultset('JournalsAuth')->create({
        title    => $title,
        created  => $timestamp,
        modified => $timestamp,
    });

    $journal_auth->add_to_titles({
        title        => $title,
        title_count  => 1
    });

    $journal->journal_auth( $journal_auth->id );
    $journal->update;

    foreach my $issn (@$issns) {
        $journal_auth->add_to_issns({
                issn => $issn,
                info => 'CUFTS (initial load)',
        });
    }

    $stats->{new_record}++;

    $options->{progress} and print "!";

    return $journal_auth;
}

sub update_ja_record {
    my ( $schema, $journal_auth, $journal, $issns, $timestamp, $stats, $options ) = @_;

    my @journal_auth_issns = map { $_->issn } $journal_auth->issns;

    # Test ISSNs - don't create records with duplicate ISSNS and
    # don't naively merge records that already have two ISSNs

    my $new_issn_count = 0;
    foreach my $issn (@$issns) {
        if ( !grep { $issn eq $_ } @journal_auth_issns ) {

            my @issns = $schema->resultset('JournalsAuthISSNs')->search({ issn => $issn })->all;
            if ( scalar @issns ) {
                push @{$stats->{ issn_dupe }}, $journal;
                return undef;
            }
            $new_issn_count++;

        }
    }

    if ($new_issn_count && ( $new_issn_count + scalar(@journal_auth_issns) ) > 2) {
        push @{$stats->{ too_many_issns }}, flatten_for_stats($journal);
        return undef;
    }

    $journal->journal_auth( $journal_auth->id );
    $journal->update;

    my $title = trim($journal->title);

    my $title_rec = $schema->resultset('JournalsAuthTitles')->find_or_create({
            title        => $title,
            journal_auth => $journal_auth->id
    });
    $title_rec->title_count( $title_rec->title_count + 1 );
    $title_rec->update;

    foreach my $issn (@$issns) {
        if ( !grep { $issn eq $_ } @journal_auth_issns ) {

            $journal_auth->add_to_issns({
                issn => $issn,
                info => 'CUFTS (initial load)'
            });

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
    my $class = shift;
    my $schema = shift;
    my @ids = @_;

    return undef if !scalar @ids > 1;

    # Merge down to the first id passed in
    my $journal_auth = $schema->resultset('JournalsAuth')->find({ id => shift @ids });

    foreach my $ja_id (@ids) {

        my $old_journal_auth = $schema->resultset('JournalsAuth')->find({ id => $ja_id });

        $class->merge_ja_issns(  $journal_auth, $old_journal_auth );
        $class->merge_ja_titles( $journal_auth, $old_journal_auth );
        $class->merge_cjdb_tags(     $journal_auth, $old_journal_auth );

        $class->merge_cjdb_journals( $journal_auth, $old_journal_auth );

        $class->update_journals( $journal_auth, $old_journal_auth );

        $old_journal_auth->delete();
    }

    return $journal_auth;
}

sub update_journals {
    my ( $class, $journal_auth, $old_journal_auth ) = @_;

    my $rs = $old_journal_auth->global_journals;
    while ( my $journal = $rs->next ) {
        $journal->update({ journal_auth => $journal_auth->id });
    }

    $rs = $old_journal_auth->local_journals;
    while ( my $journal = $rs->next ) {
        $journal->update({ journal_auth => $journal_auth->id });
    }

    return 1;
}


sub merge_ja_issns {
    my ( $class, $journal_auth, $old_journal_auth ) = @_;

    foreach my $issn ( $old_journal_auth->issns->all ) {
        $journal_auth->issns->find_or_create({ issn => $issn->issn });
        $issn->delete();
    }

    return 1;
}

sub merge_ja_titles {
    my ( $class, $journal_auth, $old_journal_auth ) = @_;

    foreach my $title ( $old_journal_auth->titles->all ) {

        my $record = {};
        foreach my $column ( $title->columns ) {
            next if grep { $_ eq $column } qw{ id journal_auth };
            $record->{$column} = $title->$column();
        }

        my $existing = $journal_auth->titles({ title => $record->{title} })->first;

        if ($existing) {
            $existing->title_count($existing->title_count() + $record->{title_count});
            $existing->update;
        }
        else {
            $journal_auth->add_to_titles($record);
        }

        $title->delete();
    }

    return 1;
}

sub merge_cjdb_journals {
    my ( $class, $journal_auth, $old_journal_auth ) = @_;


    my $old_journals_rs = $old_journal_auth->cjdb_journals;
    while ( my $old_journal = $old_journals_rs->next ) {

        my $new_journals_rs = $journal_auth->cjdb_journals({ site => $old_journal->site->id });
        if ( $new_journals_rs->count ) {
            while ( my $new_journal = $new_journals_rs->next ) {
                $class->merge_cjdb_titles(       $new_journal, $old_journal );
                $class->merge_cjdb_links(        $new_journal, $old_journal );
                $class->merge_cjdb_subjects(     $new_journal, $old_journal );
                $class->merge_cjdb_issns(        $new_journal, $old_journal );
                $class->merge_cjdb_associations( $new_journal, $old_journal );
                $class->merge_cjdb_relations(    $new_journal, $old_journal );

                $old_journal->delete();
            }
        }
        else {
            $old_journal->journals_auth( $journal_auth->id );
            $old_journal->update();
        }

    }

    return 1;
}

sub merge_cjdb_titles {
    my ( $class, $cjdb_journal, $old_cjdb_journal ) = @_;

    my @titles = map { $_->id } $cjdb_journal->journals_titles->all;

    foreach my $journal_title ( $old_cjdb_journal->journals_titles->all ) {

        my $title_id = $journal_title->title->id;

        if ( grep { $title_id eq $_ } @titles ) {
            $journal_title->delete();
        }
        else {
            $journal_title->update({ journal => $cjdb_journal->id });
        }

    }

    return 1;
}

sub merge_cjdb_links {
    my ( $class, $cjdb_journal, $old_cjdb_journal ) = @_;

    my @links = map { $_->url } $cjdb_journal->links->all;

    foreach my $link ( $old_cjdb_journal->links->all ) {

        if ( grep { $link->url eq $_ } @links ) {
            $link->delete();
        }
        else {
            $link->update({ journal => $cjdb_journal->id });
        }

    }

    return 1;
}


sub merge_cjdb_associations {
    my ( $class, $cjdb_journal, $old_cjdb_journal ) = @_;

    my @associations = map { $_->id } $cjdb_journal->journals_associations->all;

    foreach my $association ( $old_cjdb_journal->journals_associations->all ) {

        my $association_id = $association->association->id;

        if ( grep { $association_id eq $_ } @associations ) {
            $association->delete();
        }
        else {
            $association->update({ journal => $cjdb_journal->id });
        }

    }

    return 1;
}

sub merge_cjdb_subjects {
    my ( $class, $cjdb_journal, $old_cjdb_journal ) = @_;

    my @subjects = map { $_->id } $cjdb_journal->journals_subjects->all;

    foreach my $subject ( $old_cjdb_journal->journals_subjects->all ) {

        my $subject_id = $subject->subject->id;

        if ( grep { $subject_id eq $_ } @subjects ) {
            $subject->delete();
        }
        else {
            $subject->update({ journal => $cjdb_journal->id });
        }

    }

    return 1;
}


sub merge_cjdb_relations {
    my ( $class, $cjdb_journal, $old_cjdb_journal ) = @_;

    my @relations = map { $_->title } $cjdb_journal->relations->all;

    foreach my $relation ($old_cjdb_journal->relations->all) {

        if ( grep { $relation->title eq $_ } @relations ) {
            $relation->delete();
        }
        else {
            $relation->update({ journal => $cjdb_journal->id });
        }

    }

    return 1;
}


sub merge_cjdb_issns {
    my ( $class, $cjdb_journal, $old_cjdb_journal ) = @_;

    my @issns = map { $_->issn } $cjdb_journal->issns->all;

    foreach my $issn ($old_cjdb_journal->issns->all) {

        if ( grep { $issn->issn eq $_ } @issns ) {
            $issn->delete();
        }
        else {
            $issn->update({ journal => $cjdb_journal->id });
        }

    }

    return 1;
}


sub merge_cjdb_tags {
    my ( $class, $journal_auth, $old_journal_auth ) = @_;

    foreach my $tag ( $old_journal_auth->cjdb_tags->all ) {

        # Check for existing tag on new journal
        my $count = $journal_auth->cjdb_tags({
                tag          => $tag->tag,
                account      => $tag->account->id,
        })->count;

        if ( $count ) {
            $tag->delete;
        }
        else {
            $tag->update({ journals_auth => $journal_auth->id });
        }
    }

    return 1;
}


1;
