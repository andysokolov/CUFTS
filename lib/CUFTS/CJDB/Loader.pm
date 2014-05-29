package CUFTS::CJDB::Loader;

use CUFTS::CJDB::Util;
use CUFTS::Util::Simple;

use List::MoreUtils qw(uniq);
use String::Util qw(hascontent trim);

use Data::Dumper;
use strict;

use Moose;

has 'site_id' => (
    is => 'rw',
    isa => 'Int',
);

has 'schema' => (
    is => 'rw',
    isa => 'Object',
);


my $__CJDB_LOADER_DEBUG = 0;

sub skip_record {
    my ( $self, $record ) = @_;
    return 0;
}

sub pre_process {
    my ( $self, @files ) = @_;
    return @files;
}

# get ISSNs, clean up dupes and remove entries that are also in 78.x fields ("continues", and "proceeded by")

sub get_clean_issn_list {
    my ( $self, $record ) = @_;
    my @issns = $self->get_issns($record);

    # Try removing possible 78.x related ISSNs to avoid multiple matches

    my @seveneight_fields = $self->get_ceding_fields_issns($record);
    my @temp_issns;
    foreach my $issn (@issns) {
        if ( !grep { $_ eq $issn } @seveneight_fields ) {
            push @temp_issns, $issn;
        }
    }

    # Only use this new issn array if we haven't gotten rid of all the ISSNs

    scalar(@temp_issns)
        and @issns = @temp_issns;

    return @issns;
}

# journals_auth may be a journals_auth object, or a journals_auth id that requires retrieving

sub load_journal {
    my ( $self, $record, $journals_auth, $no_save ) = @_;

    my $site_id = $self->site_id
        or die("No site id set for loader.");

    my $title = $self->get_title($record);
    if ( is_empty_string($title) || $title eq '0' ) {
        print "Empty title, skipping record.\n";
        return undef;
    }
    if ( length($title) > 1024 ) {
        print "Title too long, skipping record: $title\n";
        return undef;
    }

    $__CJDB_LOADER_DEBUG and print "title: $title\n";

    my $sort_title          = $self->get_sort_title($record);
    my $stripped_sort_title = $self->strip_title($sort_title);

    # Get clean list of ISSNs

    my @issns = $self->get_clean_issn_list($record);

    $__CJDB_LOADER_DEBUG and print "issns: " . join(',', @issns) . "\n";


    # Consider modifying simple titles like "Journal" and "Review" by adding
    # an association.  This might need to be a site option later on.

    $self->fix_bad_titles( $record, \$title, \$sort_title, \$stripped_sort_title );

    # Find or create a journals_auth record to associate with


    my $journals_auth_id;

    if ( ref $journals_auth ) {
        # Already have a passed in journals_auth object
        $journals_auth_id = $journals_auth->id;
    }
    elsif ( defined $journals_auth ) {
        # Passed in journals_auth_id, get it from the database
        $journals_auth_id = $journals_auth;
        $journals_auth = $self->schema->resultset('JournalsAuth')->find({ id => $journals_auth_id });
    }
    else {
        # Try to find a journals_auth record based on ISSNs and title
        $journals_auth_id = $self->get_journals_auth( \@issns, $title, $record )
            or return undef;
        $journals_auth = $self->schema->resultset('JournalsAuth')->find({ id => $journals_auth_id });
    }

    $__CJDB_LOADER_DEBUG and print "ja found\n";

    if ( $self->merge_by_issns ) {
        my @journals = $self->schema->resultset('CJDBJournals')->search({ journals_auth => $journals_auth_id, site => $site_id })->all;
        return $journals[0] if scalar @journals;
    }

    # Add on the first call number if we have it

    my $call_numbers = $self->get_call_numbers($record);

    # Create the journal record

    my $new_journal_record = {
            title               => $title,
            sort_title          => $sort_title,
            stripped_sort_title => $stripped_sort_title,
            site                => $site_id,
            journals_auth       => $journals_auth_id,
            call_number         => shift @$call_numbers,
    };

    if ( not_empty_string( $journals_auth->rss) ) {
        $new_journal_record->{rss} = $journals_auth->rss;
    }

    my $journal = $self->schema->resultset('CJDBJournals')->create( $new_journal_record );

    CJDB::Exception::App->throw('Unable to create new journal record.') if !defined $journal;

    foreach my $issn ( uniq(@issns) ) {
        $journal->add_to_issns({
               site    => $site_id,
               issn    => $issn,
        });
    }

    return $journal;
}


sub match_journals_auth {
    my ( $self, $record, $no_save ) = @_;

    my $site_id = $self->site_id
        or die("No site id set for loader.");

    $no_save = 1 if !defined($no_save);

    my $title = $self->get_title($record);
    if ( is_empty_string($title) || $title eq '0' ) {
        print "Empty title, skipping record.\n";
        return undef;
    }
    if ( length($title) > 1024 ) {
        print "Title too long, skipping record: $title\n";
        return undef;
    }

    $__CJDB_LOADER_DEBUG and print "title: $title\n";

    my $sort_title          = $self->get_sort_title($record);
    my $stripped_sort_title = $self->strip_title($sort_title);

    # Get clean list of ISSNs

    my @issns = $self->get_clean_issn_list($record);

    # Consider modifying simple titles like "Journal" and "Review" by adding
    # an association.  This might need to be a site option later on.

    $self->fix_bad_titles( $record, \$title, \$sort_title, \$stripped_sort_title );

    # Find a journals_auth record to associate with

    return $self->get_journals_auth( \@issns, $title, $record, $no_save );
}

sub fix_bad_titles {
    my ( $self, $record, $title_ref, $sort_title_ref, $stripped_sort_title_ref ) = @_;

    foreach my $bad_title (@CUFTS::CJDB::Util::generic_titles) {
        if ( $$stripped_sort_title_ref eq $bad_title ) {
            my @associations = $self->get_associations($record);
            my @final_associations;
            foreach my $association (@associations) {
                next if $association =~ /journal/i;
                push @final_associations, $association;
            }

            # Grab the first assn/org, but consider adding code to
            # add the others as extra additional titles

            if ( scalar(@final_associations) ) {
                $$title_ref      =~ s{ \s* / \s* $}{}xsm;
                $$sort_title_ref =~ s{ \s* / \s* $}{}xsm;

                $$title_ref      = $$title_ref      . ' / ' . $final_associations[0];
                $$sort_title_ref = $$sort_title_ref . ' / ' . $final_associations[0];

                $$stripped_sort_title_ref = $self->strip_title($$sort_title_ref);
            }
        }
    }

    return 1;
}

sub load_titles {
    my ( $self, $record, $journal, $site_id ) = @_;

    defined($site_id)
        or $site_id = $self->site_id;

    my @search_titles;

    # Add the main journal record title to the titles table

    my $title               = $journal->title;
    my $sort_title          = $journal->sort_title;
    my $stripped_sort_title = $journal->stripped_sort_title;

    push @search_titles, [ $stripped_sort_title, $sort_title, 1 ];

    # Add the print title if it's different than the main title.
    # This happens if a second print record matches an earlier loaded
    # print record.

    my $record_sort_title = $self->get_sort_title($record);
    my $record_stripped_sort_title = $self->strip_title($record_sort_title);
    if ($record_stripped_sort_title ne $stripped_sort_title) {
            push @search_titles, [$record_stripped_sort_title, $record_sort_title, 0];
    }

    # Add alternate titles

    push @search_titles, $self->get_alt_titles($record);

    my $count = 0;
    foreach my $title (@search_titles) {
        next if   is_empty_string($title->[0])
               || is_empty_string($title->[1]);

        next if length($title) > 1024;

        my $title = $self->schema->resultset('CJDBTitles')->find_or_create({
                title        => $title->[1],
                search_title => $title->[0],
        })->id;

        $self->schema->resultset('CJDBJournalsTitles')->find_or_create({
                journal => $journal->id,
                title   => $title->id,
                main    => $title->[2] ? 1 : 0,
                site    => $site_id,
        });

        $count++;
    }

    return $count;
}

sub load_MARC_subjects {
    my ( $self, $record, $journal, $site_id ) = @_;

    defined($site_id)
        or $site_id = $self->site_id;

    my @subjects = $self->get_MARC_subjects($record);

    my $count = 0;
    foreach my $subject (@subjects) {

        my $cjdb_subject = $self->schema->resultset('CJDBSubjects')->find_or_create({
                subject        => $subject,
                search_subject => $self->strip_title($subject),
        });

        my $new_subject = {
            journal  => $journal->id,
            site     => $site_id,
            subject  => $cjdb_subject->id,
        };

        my @subjects = $self->schema->resultset('CJDBJournalsSubjects')->search($new_subject)->all;
        next if scalar @subjects;

        $new_subject->{origin} = 'MARC';

        $self->schema->resultset('CJDBJournalsSubjects')->create($new_subject);

        $count++;
    }

    return $count;
}

sub load_LCC_subjects {
    my ( $self, $record, $journal, $site_id ) = @_;

    defined($site_id)
        or $site_id = $self->site_id;

    my $subjects = $self->get_LCC_subjects( $record, $site_id );

    my @total_subjects;

    foreach my $subject (@$subjects) {
        defined( $subject->subject1 )
            and push @total_subjects, $subject->subject1;
        defined( $subject->subject2 )
            and push @total_subjects, $subject->subject2;
        defined( $subject->subject3 )
            and push @total_subjects, $subject->subject3;
    }

    my $count = 0;
    foreach my $subject (@total_subjects) {

        my $cjdb_subject = $self->schema->resultset('CJDBSubjects')->find_or_create({
                subject        => $subject,
                search_subject => $self->strip_title($subject),
        });

        my $new_subject = {
            journal  => $journal->id,
            site     => $site_id,
            subject  => $cjdb_subject->id,
        };

        my @subjects = $self->schema->resultset('CJDBJournalsSubjects')->search($new_subject);
        next if scalar @subjects;

        $new_subject->{origin} = 'LCC';

        $self->schema->resultset('CJDBJournalsSubjects')->create($new_subject);

        $count++;
    }

    return $count;
}

sub get_LCC_subjects {
    my ( $self, $record, $site_id ) = @_;

    my @subjects;

    my $call_numbers = $self->get_call_numbers($record);
    foreach my $call_number (@$call_numbers) {

        if ( defined($call_number) && $call_number =~ /([A-Z]{1,3}) \s* ([\d]+)/xsm ) {
            my ( $class, $number ) = ( $1, $2 );
            my $subject_search = {
                number_high => { '>=', $number },
                number_low  => { '<=', $number },
                class_high  => { '>=', $class },
                class_low   => { '<=', $class }
            };

            if ( $self->schema->resultset('CJDBLCCSubjects')->search({ site => $site_id })->count > 0 ) {
                $subject_search->{site} = $site_id;
            }

            push @subjects, $self->schema->resultset('CJDBLCCSubjects')->search($subject_search)->all;
        }

    }

    return \@subjects;
}

sub get_call_numbers {
    my ( $self, $record ) = @_;

    return [];
}

sub load_associations {
    my ( $self, $record, $journal, $site_id ) = @_;

    defined($site_id)
        or $site_id = $self->site_id;

    my @associations = $self->get_associations($record);

    my $count = 0;

    foreach my $association (@associations) {

        my $cjdb_association = $self->schema->resultset('CJDBAssociations')->find_or_create({
                association        => $association,
                search_association => $self->strip_title($association),
        });

        $self->schema->resultset('CJDBJournalsAssociations')->find_or_create({
                association  => $cjdb_association->id,
                journal      => $journal->id,
                site         => $site_id,
        });

        $count++;
    }

    return $count;
}

sub load_relations {
    my ( $self, $record, $journal, $site_id ) = @_;

    defined($site_id)
        or $site_id = $self->site_id;

    my @relations = $self->get_relations($record);

    my $count = 0;

    foreach my $relation (@relations) {
        next if !defined( $relation->{title} );

        $self->schema->resultset('CJDBRelations')->find_or_create({
            journal  => $journal->id,
            site     => $site_id,
            relation => $relation->{relation},
            title    => $relation->{title},
            issn     => $relation->{issn},
        });

        $count++;
    }

    return $count;
}

sub load_extras {
    my ( $self, $record, $journal, $site_id ) = @_;

    my $image = $self->get_image($record);
    if ( defined($image) ) {
        $journal->image($image);
    }

    my $image_link = $self->get_image_link($record);
    if ( defined($image_link) ) {
        $journal->image_link($image_link);
    }

    my $rss = $self->get_rss($record);
    if ( defined($rss) ) {
        $journal->rss($rss);
    }

    my $misc = $self->get_miscellaneous($record);
    if ( defined($misc) ) {
        $journal->miscellaneous($misc);
    }

    $journal->update;

    return 0;
}

sub load_link {
    my ( $self, $record, $journal, $site_id ) = @_;

    defined($site_id)
        or $site_id = $self->site_id;

    my $coverage = $self->get_coverage($record);
    my $link     = $self->get_link($record);
    my $rank     = $self->get_rank();

    $__CJDB_LOADER_DEBUG and print "links: $coverage : $link : $rank\n";

    defined($coverage) && defined($link)
        or return 0;

    $self->schema->resultset('CJDBLinks')->find_or_create({
        journal        => $journal->id,
        link_type      => 0,
        url            => $link,
        print_coverage => $coverage || 'unknown',
        site           => $site_id,
        rank           => $rank,
    });

    return 1;
}

sub strip_title {
    my ( $self, $string ) = @_;

    return CUFTS::CJDB::Util::strip_title($string);
}

sub merge_by_issns {
    my ($self) = @_;
    return 0;
}

sub load_resources_as_associations {
    return 1;
}

sub strip_articles {
    my ( $self, $string ) = @_;

    # Default to the CJDB::Util module version, however make
    # this a Loader method so it can be overridden

    return CUFTS::CJDB::Util::strip_articles($string);
}

sub get_journals_auth {
    my ( $self, $issns, $title, $record, $no_save ) = @_;

    # Remove backslashes that make Pg think the next character is quoted... may need to do other chars later, too.
    # Might as well totally strip it from the title, backslashes probably aren't relevant in titles and are
    # part of weird MARC coding.
    my $title_no_bs = $title;
    $title_no_bs =~ s/\s*\\\s*//g;

    my @journals_auths;

    if ( scalar @$issns ) {
        @journals_auths = $self->schema->resultset('JournalsAuth')->search_by_issns(@$issns)->all;

        if ( scalar @journals_auths == 1 ) {
            return $journals_auths[0]->id;
        } elsif ( scalar @journals_auths > 1 ) {

            # Try title ranking

            my $title_ranks = $self->rank_titles( $record, $title_no_bs, \@journals_auths );

            my ( $max, $max_count, $index ) = ( 0, 0, -1 );
            foreach my $x ( 0 .. $#$title_ranks ) {
                if ( $title_ranks->[$x] > $max ) {
                    $max       = $title_ranks->[$x];
                    $index     = $x;
                    $max_count = 1;
                }
                elsif ( $title_ranks->[$x] == $max ) {
                    $max_count++;
                }
            }

            if ( $max_count == 1 ) {
                return $journals_auths[$index]->id;
            }
            else {
                print( "Could not find unambiguous match for $title_no_bs -- ", join( ',', @$issns ), "\n" );
                return undef;
            }

        }
    }
    else {

        # Try for strictly title matching

        @journals_auths = $self->schema->resultset('JournalsAuth')->search_by_exact_title_with_no_issns($title_no_bs)->all;
        if ( !scalar @journals_auths ){
            @journals_auths = $self->schema->resultset('JournalsAuth')->search_by_title_with_no_issns($title_no_bs)->all;
        }
        if ( !scalar @journals_auths ){
            @journals_auths = $self->schema->resultset('JournalsAuth')->search_by_title($title_no_bs)->all;
        }

        if ( scalar @journals_auths > 1 ) {
            print(
                "Could not find unambiguous main title match for $title_no_bs ($title) -- ",
                join( ',', @$issns ),
                "\n"
            );
            return undef;
        }
        elsif ( scalar @journals_auths == 1 ) {
            return $journals_auths[0]->id;
        }
        else {

            # Alternate title matches

            foreach my $title_arr (
                $self->get_alt_titles($record),
                [   $self->strip_title( $self->get_sort_title($record) ),
                    $self->get_sort_title($record)
                ],
            ) {
                my $alt_title = $title_arr->[1];
                $alt_title =~ s/\\//g;  # Strip backslashes which break Pg searches
                my @temp_journals_auth = $self->schema->resultset('JournalsAuth')->search_by_title($alt_title)->all;
                foreach my $temp_journal (@temp_journals_auth) {
                    grep { $_->id == $temp_journal->id } @journals_auths
                        or push @journals_auths, $temp_journal;
                }
            }
            if ( scalar @journals_auths > 1 ) {
                print(
                    "Could not find unambiguous alternate title match for $title -- ",
                    join( ',', @$issns ),
                    "\n"
                );
                return undef;
            }
            elsif ( scalar @journals_auths == 1 ) {
                return $journals_auths[0]->id;
            }
        }
    }

    return undef if $no_save;

    # Build basic record

    my $journals_auth = $self->schema->resultset('JournalsAuth')->create({ title => $title_no_bs });
    $journals_auth->add_to_titles( { title => $title_no_bs, title_count => 1 } );

    foreach my $issn ( uniq(@$issns) ) {
        $journals_auth->add_to_issns( { issn => $issn } );
    }

    return $journals_auth->id;
}

sub rank_titles {
    my ( $self, $record, $print_title, $journals_auths ) = @_;

    my $stripped_print_title = CUFTS::CJDB::Util::strip_title_for_matching( CUFTS::CJDB::Util::strip_title($print_title) );
    $stripped_print_title =~ tr/a-z0-9 //cd;

    my @alt_titles = $self->get_alt_titles($record);

    my @ranks;
    foreach my $x ( 0 .. $#$journals_auths ) {
        my $journals_auth = $journals_auths->[$x];

        $ranks[$x] = $self->compare_titles( $journals_auth->title, $print_title );
        if ( $ranks[$x] < 50 ) {
            foreach my $title ( $journals_auth->titles ) {
                my $new_rank = ( $self->compare_titles( $title->title, $print_title ) / 2 ) + 1;
                $new_rank > $ranks[$x]
                    and $ranks[$x] = $new_rank;
            }
        }
    }

    return \@ranks;
}

sub compare_titles {
    my ( $self, $title1, $title2 ) = ( shift, lc(shift), lc(shift) );

    my $stripped_title1 = CUFTS::CJDB::Util::strip_title_for_matching( CUFTS::CJDB::Util::strip_title($title1) );
    my $stripped_title2 = CUFTS::CJDB::Util::strip_title_for_matching( CUFTS::CJDB::Util::strip_title($title2) );

    $stripped_title1 =~ tr/a-z0-9 //cd;
    $stripped_title2 =~ tr/a-z0-9 //cd;

    if ( $title1 eq $title2 ) {
        return 100;
    }
    elsif ( $stripped_title1 eq $stripped_title2 ) {
        return 75;
    }
    elsif ( $self->compare_title_words( $stripped_title1, $stripped_title2 ) ) {
        return 50;
    }
    elsif ( CUFTS::CJDB::Util::title_match( [$stripped_title1], [$stripped_title2] ) ) {
        return 25;
    }

    return 0;
}

# Checks if titles contain all the same words, but in a different order

sub compare_title_words {
    my ( $self, $title1, $title2 ) = @_;
    my ( %title1, %title2 );

    foreach my $word ( split / /, $title1 ) {
        $title1{$word}++;
    }

    foreach my $word ( split / /, $title2 ) {
        $title2{$word}++;
    }

    foreach my $key ( keys %title1 ) {
        if ( exists $title2{$key} && $title1{$key} == $title2{$key} ) {
            delete $title1{$key};
            delete $title2{$key};
        }
        else {
            return 0;
        }
    }

    if ( scalar(keys(%title1)) == 0 && scalar(keys(%title2)) == 0 ) {
        return 1;
    }
    else {
        return 0;
    }

}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
