package CUFTS::CJDB4::Controller::Browse;
use Moose;
use namespace::autoclean;

use String::Util qw( trim hascontent );
use CUFTS::CJDB::Util;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

CUFTS::CJDB4::Controller::Browse - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 base

=cut

sub base :Chained('../site') :PathPart('browse') :CaptureArgs(0) {
    my ( $self, $c ) = @_;

    push @{$c->stash->{breadcrumbs}}, [ $c->uri_for_site( $c->controller('Browse')->action_for('browse') ), $c->loc('Journals') ];
}


=head2 browse

=cut

sub browse :Chained('base') :PathPart('') :Args(0) {
    my ($self, $c) = @_;

    $c->stash->{template} = 'browse.tt';
}

sub titles :Chained('base') :PathPart('titles') :Args(0) {
    my ($self, $c) = @_;

	my $site_id     = $c->site->id;
	my $search_term = $c->req->params->{q};
	my $search_type = $c->req->params->{t};
	my $page        = $c->req->params->{page} || 1;
	my $rows        = $c->req->params->{per_page} || 50;    # TODO: Customize this per site

	my $cleaned_search_term = CUFTS::CJDB::Util::strip_title( CUFTS::CJDB::Util::strip_articles($search_term) );

    if ( $search_type eq 'ft' ) {
        $c->stash->{journals_rs} = $c->model('CUFTS::CJDBJournals')->search_distinct_title_by_journal_main_ft( $site_id, $cleaned_search_term, $page, $rows );
    }
    else {
        if ( $search_type eq 'startswith' ) {
            $cleaned_search_term = '^' . quotemeta($cleaned_search_term);
        }
        elsif ( $search_type eq 'advstartswith' ) {  # !!! No regex quoting, this is used internally
            $cleaned_search_term = '^' . lc(CUFTS::CJDB::Util::strip_articles($search_term)) . '.*';
        }
        if ( $search_type eq 'exact' ) {
            $cleaned_search_term = '^' . quotemeta($cleaned_search_term) . '$';
        }

        $c->stash->{journals_rs} = $c->model('CUFTS::CJDBJournals')->search_distinct_title_by_journal_main( $site_id, $cleaned_search_term, $page, $rows );
    }

    # If a JSON response is wanted, create the results and return the JSON view

    if ( defined($c->req->params->{format}) && $c->req->params->{format} eq 'json' ) {
        $c->stash->{json} = {
            total_count     => $c->stash->{journals_rs}->pager->total_entries,
            start_page      => int($page),
            per_page        => int($rows),
            journals        => [ map { _journal_object_to_hash($c, $_) } $c->stash->{journals_rs}->all ],
        };
        return $c->forward('View::JSON');
    }

    # For optimization reasons, go get all the ISSNs and links. Doing it this way means two big database calls rather
    # than 200 small ones. Even to a local database it's about twice as fast.

    my @journals = $c->stash->{journals_rs}->all;
    my @ids      = map {$_->id} @journals;
    _stash_issns($c, \@ids);
    _stash_links($c, \@ids);


    $c->stash->{journals}        = \@journals;
    $c->stash->{browse_form_tab} = 'title';
    $c->stash->{pager}           = $c->stash->{journals_rs}->pager;
    $c->stash->{template}        = 'browse_journals.tt';

    push @{$c->stash->{breadcrumbs}}, [ $c->uri_for_site( $c->controller('Browse')->action_for('titles') ), $c->loc('Titles') ];
}

sub bylink :Chained('base') :PathPart('bylink') :Args(2) {
    my ($self, $c, $type, $id) = @_;

    my $page  = $c->req->params->{page} || 1;
    my $rows  = $c->req->params->{per_page} || 50;    # TODO: Customize this per site

    my $journals_rs = $c->model('CUFTS::CJDBJournals')->search(
        {
            'me.site' => $c->site->id,
        },
        {
            page => $page,
            rows => $rows,
            order_by => 'stripped_sort_title',
        }
    );

    if ( $type eq 'subject' ) {
        $c->stash->{journals_rs} = $journals_rs->search( { 'journals_subjects.subject' => $id }, { join => [ 'journals_subjects' ] } );
        $c->stash->{browse_type} = $type;
        $c->stash->{browse_value} = $c->model('CUFTS::CJDBSubjects')->find($id)->subject;
        push @{$c->stash->{breadcrumbs}}, [ $c->uri_for_site( $c->controller('Browse')->action_for('bylink'), [ $type, $id ] ), $c->loc('By Subject') ];

    }
    elsif ( $type eq 'association' ) {
        $c->stash->{journals_rs} = $journals_rs->search( { 'journals_associations.association' => $id }, { join => [ 'journals_associations' ] } );
        $c->stash->{browse_type} = $type;
        $c->stash->{browse_value} = $c->model('CUFTS::CJDBAssociations')->find($id)->association;
        push @{$c->stash->{breadcrumbs}}, [ $c->uri_for_site( $c->controller('Browse')->action_for('bylink'), [ $type, $id ] ), $c->loc('By Association') ];
    }

    # For optimization reasons, go get all the ISSNs and links. Doing it this way means two big database calls rather
    # than 200 small ones. Even to a local database it's about twice as fast.

    my @journals = $c->stash->{journals_rs}->all;
    my @ids      = map {$_->id} @journals;
    _stash_issns($c, \@ids);
    _stash_links($c, \@ids);

    $c->stash->{journals} = \@journals;
    $c->stash->{pager}    = $c->stash->{journals_rs}->pager;
    $c->stash->{template} = 'browse_journals.tt';
}

sub subjects :Chained('base') :PathPart('subjects') :Args(0) {
    my ($self, $c) = @_;

    my $site_id     = $c->site->id;
    my $search_term = $c->req->params->{q};
    my $search_type = $c->req->params->{t};
    my $page        = $c->req->params->{page} || 1;
    my $rows        = $c->req->params->{per_page} || 50;    # TODO: Customize this per site

    my $cleaned_search_term = CUFTS::CJDB::Util::strip_title( CUFTS::CJDB::Util::strip_articles($search_term) );

    if ( $search_type eq 'startswith' ) {
        $cleaned_search_term .= '%';
    }
    elsif ( $search_type eq 'equals' ) {
        # Legitimately do nothing - this is for documentation.
    }
    else {
        $cleaned_search_term = '%' . $cleaned_search_term . '%';
    }

    $c->stash->{subjects_rs} = $c->model('CUFTS::CJDBSubjects')->search(
        {
            site                => $site_id,
            'me.search_subject' => { 'like' => $cleaned_search_term },
        },
        {
            group_by     => [ 'me.id', 'me.search_subject', 'me.subject' ],
            join         => [ 'journals_subjects' ],
            page         => $page,
            rows         => $rows,
            order_by     => 'search_subject',
        }
    );

    $c->stash->{browse_form_tab} = 'subject';
    $c->stash->{pager}           = $c->stash->{subjects_rs}->pager;
    $c->stash->{template}        = 'browse_subjects.tt';
    push @{$c->stash->{breadcrumbs}}, [ $c->uri_for_site( $c->controller('Browse')->action_for('subjects') ), $c->loc('Subjects') ];
}


sub associations :Chained('base') :PathPart('associations') :Args(0) {
    my ($self, $c) = @_;

    my $site_id     = $c->site->id;
    my $search_term = $c->req->params->{q};
    my $search_type = $c->req->params->{t};
    my $page        = $c->req->params->{page} || 1;
    my $rows        = $c->req->params->{per_page} || 50;    # TODO: Customize this per site

    my $cleaned_search_term = CUFTS::CJDB::Util::strip_title( $search_term );

    if ( $search_type eq 'startswith' ) {
        $cleaned_search_term .= '%';
    }
    else {
        $cleaned_search_term = '%' . $cleaned_search_term . '%';
    }

    $c->stash->{associations_rs} = $c->model('CUFTS::CJDBAssociations')->search(
        {
            site                    => $site_id,
            'me.search_association' => { 'like' => $cleaned_search_term },
        },
        {
            group_by     => [ 'me.id', 'me.search_association', 'me.association' ],
            join         => [ 'journals_associations' ],
            page         => $page,
            rows         => $rows,
            order_by     => 'search_association',
        }
    );

    $c->stash->{browse_form_tab} = 'association';
    $c->stash->{pager}           = $c->stash->{associations_rs}->pager;
    $c->stash->{template}        = 'browse_associations.tt';

    push @{$c->stash->{breadcrumbs}}, [ $c->uri_for_site( $c->controller('Browse')->action_for('associations') ), $c->loc('Associations') ];
}


sub tags :Chained('base') :PathPart('tags') :Args(0) {
    my ($self, $c) = @_;

    my $site_id     = $c->site->id;
    my $search_term = $c->req->params->{q};
    my $page        = $c->req->params->{page} || 1;
    my $rows        = $c->req->params->{per_page} || 50;    # TODO: Customize this per site
    my $limit_to    = $c->req->params->{limit_to};
    my $level       = $c->req->params->{level};

    $search_term = ref($search_term) eq 'ARRAY' ? $search_term : [$search_term];
    my @tags = map { CUFTS::CJDB::Util::strip_tag($_) } map {split /,/} @$search_term;


    # If a viewing level has not been defined, check the local param for local search only,
    # or default to public + local (3).

    my $viewing =   defined($c->req->params->{viewing})  ? $c->req->params->{viewing}
                  : $c->req->params->{local}             ? 2
                  :                                        3;

    # Add account to the parameters so that /browse/bytags will search on only that account

    if ( scalar(@tags) ) {
        my $rs = $c->model('CUFTS::CJDBJournals')->search_distinct_by_tags( \@tags, $level, $c->site, $c->account, $viewing );

        $rs = $rs->search({}, { page => $page, rows => $rows, order_by => 'stripped_sort_title' });

        if ( $limit_to eq 'mytags' && $c->has_account ) {
            $rs = $rs->search({ 'tags.account' => $c->account->id });
        }

        $c->stash->{journals_rs} = $rs;
        $c->stash->{pager}       = $c->stash->{journals_rs}->pager;

    }
    else {
        $c->stash->{errors} = [ 'Empty search' ];
    }


    # For optimization reasons, go get all the ISSNs and links. Doing it this way means two big database calls rather
    # than 200 small ones. Even to a local database it's about twice as fast.

    my @journals = $c->stash->{journals_rs}->all;
    my @ids      = map {$_->id} @journals;
    _stash_issns($c, \@ids);
    _stash_links($c, \@ids);


    $c->stash->{journals}        = \@journals;
    $c->stash->{browse_form_tab} = 'tag';
    $c->stash->{template}        = 'browse_journals.tt';

    push @{$c->stash->{breadcrumbs}}, [ $c->uri_for_site( $c->controller('Browse')->action_for('tags') ), $c->loc('By Tag') ];
}


sub issns :Chained('base') :PathPart('issns') :Args(0) {
    my ($self, $c) = @_;

    my $site_id     = $c->site->id;
    my $search_term = uc($c->req->params->{q});
    my $page        = $c->req->params->{page} || 1;
    my $rows        = $c->req->params->{per_page} || 50;    # TODO: Customize this per site

    $search_term =~ tr/0-9X//cd;

    if ( hascontent($search_term) ) {

        if ( length $search_term < 8 ) {
            $search_term .= '%';
        }

        my $rs = $c->model('CUFTS::CJDBJournals')->search(
            {
                'me.site'       => $site_id,
                'issns.issn'    => { 'like' => $search_term },
            },
            {
                join         => 'issns',
                page         => $page,
                rows         => $rows,
                order_by     => 'stripped_sort_title',
            }
        );

        # For optimization reasons, go get all the ISSNs and links. Doing it this way means two big database calls rather
        # than 200 small ones. Even to a local database it's about twice as fast.

        my @journals = $rs->all;
        my @ids      = map {$_->id} @journals;
        _stash_issns($c, \@ids);
        _stash_links($c, \@ids);


        $c->stash->{journals}    = \@journals;
        $c->stash->{journals_rs} = $rs;
        $c->stash->{pager}       = $c->stash->{journals_rs}->pager;

    }
    else {
        $c->stash->{errors} = [ 'Empty search' ];
    }

    $c->stash->{browse_form_tab} = 'issn';
    $c->stash->{template}        = 'browse_journals.tt';

    push @{$c->stash->{breadcrumbs}}, [ $c->uri_for_site( $c->controller('Browse')->action_for('issns') ), $c->loc('By ISSN') ];
}

sub selected_journals :Chained('base') :PathPart('selected_journals') Args(0) {
    my ($self, $c) = @_;

    $c->stash->{template} = 'selected_journals.tt';

    push @{$c->stash->{breadcrumbs}}, [ $c->uri_for_site( $c->controller('Browse')->action_for('selected_journals') ), $c->loc('Selected') ];
}


sub lcc :Chained('base') :PathPart('lcc') Args(0) {
    my ($self, $c) = @_;

    # Set up stash early since we may exit out on a cache

    $c->stash->{template}     = 'lcc_browse.tt';
    push @{$c->stash->{breadcrumbs}}, [ $c->uri_for_site( $c->controller('Browse')->action_for('lcc_browse') ), $c->loc('Subject Browse') ];

    # Check for cached LCC data since it's moderately expensive to generate

    my $cache_key = 'lcc-browse-cache-' . $c->site->id;

    my $cached = $c->cache->get($cache_key);
    if ( defined($cached) ) {
        $c->stash->{subjects}     = $cached->{subjects};
        $c->stash->{subject_info} = $cached->{subject_info};
        return;
    }

    # Check if the site has any LCC Subjects loaded. If not, fall back to using
    # the global LCC subject data.

    my $subjects_rs;
    if ( $c->model('CUFTS::CJDBLCCSubjects')->search({ site => $c->site->id })->count > 0 ) {
        $subjects_rs = $c->model('CUFTS::CJDBLCCSubjects')->search({ site => $c->site->id });
    }
    else {
        $subjects_rs = $c->model('CUFTS::CJDBLCCSubjects')->search({ site => undef });
    }

    # Build three level subject hierarchy

    my %subject_hierarchy;
    my @subjects;
    while (my $subject = $subjects_rs->next) {
        if (defined($subject->subject3) && $subject->subject3 ne '') {
            $subject_hierarchy{$subject->subject1}->{$subject->subject2}->{$subject->subject3} = {};
        } elsif (defined($subject->subject2) && $subject->subject2 ne '') {
            exists($subject_hierarchy{$subject->subject1}->{$subject->subject2}) or
                $subject_hierarchy{$subject->subject1}->{$subject->subject2} = {};
        } elsif (defined($subject->subject1) && $subject->subject1 ne '') {
            exists($subject_hierarchy{$subject->subject1}) or
                $subject_hierarchy{$subject->subject1} = {};
        }

        push @subjects, grep { hascontent($_) } ( $subject->subject1, $subject->subject2, $subject->subject3 );
    }

    # Get counts and IDs for all subjects that exist for this site in their CJDB

    my %subject_info;
    foreach my $subject (@subjects) {

        my $subject_count = $c->model('CUFTS::CJDBSubjects')->search(
            {
                site                => $c->site->id,
                'me.search_subject' => CUFTS::CJDB::Util::strip_title( CUFTS::CJDB::Util::strip_articles( $subject ) ),
            },
            {
                group_by     => [ 'me.id' ],
                select       => [ 'me.id', { count => 'journals_subjects' } ],
                as           => [ 'id', 'journal_count' ],
                join         => [ 'journals_subjects' ],
            }
        )->first;

        if ( $subject_count ) {
            $subject_info{$subject}->{id}    = $subject_count->id;
            $subject_info{$subject}->{count} = $subject_count->get_column('journal_count');
        }
    }

    $c->cache->set($cache_key,
        {
            subjects     => \%subject_hierarchy,
            subject_info => \%subject_info,
        }
    );

    $c->stash->{subjects}     = \%subject_hierarchy;
    $c->stash->{subject_info} = \%subject_info;
}

sub show :Chained('base') :PathPart('show') Args(0) {
    my ( $self, $c ) = @_;

    my $q = $c->request->params->{search_terms};
    my $field = $c->request->params->{browse_field};

    if ( $field eq 'issn' ) {
        return $c->redirect( $c->uri_for_site( $c->controller->action_for('issns'), { q => $q } ) );
    }


}



sub _stash_issns {
    my ( $c, $ids ) = @_;

    my $rs = $c->model('CUFTS::CJDBISSNs')->search({ 'me.journal' => { '-in' => $ids } });
    my %results;
    while ( my $issn = $rs->next ) {
        push @{ $results{$issn->get_column('journal')} }, $issn;
    }
    $c->stash->{issns} = \%results;
}

sub _stash_links {
    my ( $c, $ids ) = @_;

    my $rs = $c->model('CUFTS::CJDBLinks')->search_display_notes({ 'me.journal' => { '-in' => $ids } });
    my %results;
    while ( my $link = $rs->next ) {
        push @{ $results{$link->get_column('journal')} }, $link;
    }
    foreach my $id (keys %results) {
        $results{$id} = CUFTS::CJDB::Util::links_rank_name_sort( $results{$id}, $c->stash->{resources_display} );
    }
    $c->stash->{links} = \%results;
}


sub _journal_object_to_hash {
    my ( $c, $journal ) = @_;
    return {
        title               => $journal->result_title,
        url                 => $c->uri_for_site( $c->controller('Journal')->action_for('view'), $journal->get_column('journals_auth') )->as_string,
        journal_auth        => $journal->get_column('journals_auth'),
        issns               => defined($journal->issns) ? [ map { $_->issn } $journal->issns->all ] : undef,
        fulltext_coverages  => [ map { $_->fulltext_coverage } $journal->links->all ],
        links               => [
            map {
                {
                    resource          => $c->stash->{resources_display}->{ $_->resource }->{name},
                    rank              => $_->rank,
                    print_coverage    => $_->print_coverage,
                    fulltext_coverage => $_->fulltext_coverage,
                    citation_coverage => $_->citation_coverage,
                    embargo           => $_->embargo,
                    current           => $_->current,
                    url               => $_->url,
                }
            } $journal->links->all
        ],
    };
}




=head1 AUTHOR

Todd Holbrook

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
