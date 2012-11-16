package CUFTS::CJDB::Controller::Browse;
use Moose;
use namespace::autoclean;

use String::Util qw( trim hascontent );
use CUFTS::CJDB::Util;
use CUFTS::Util::Simple;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

CUFTS::CJDB::Controller::Browse - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub base :Chained('../site') :PathPart('browse') CaptureArgs(0) {
    my ( $self, $c ) = @_;

    $c->stash->{rank_name_sort} = sub {
        my ( $links, $displays ) = @_;
        my @new_array = sort { 
               int( $b->{rank} || 0 ) <=> int( $a->{rank} || 0 ) 
            or $displays->{ $a->{resource} }->{name} cmp $displays->{ $b->{resource} }->{name}
            or ( $a->print_coverage || '' ) cmp ( $b->print_coverage || '' )
            or ( $a->fulltext_coverage || '' ) cmp ( $b->fulltext_coverage || '' )
        } @$links;
        return \@new_array;
    };
}

sub browse :Chained('base') :PathPart('') Args(0) {
    my ($self, $c) = @_;

    $c->stash->{template} = 'browse.tt';
}



sub mytags :Chained('base') :PathPart('mytags') Args() {
    my ($self, $c, @tags) = @_;

    # If user is not logged in (clicked logout on this screen), bump them back to /browse

    return $c->redirect( $c->uri_for_site( $c->controller('Browse')->action_for('browse') ) ) if !defined($c->stash->{current_account});

    $c->forward( $c->controller('Browse')->action_for('bytags'), \@tags );
}


sub bytags :Chained('base') :PathPart('bytags') Args() {
    my ($self, $c, @tags) = @_;

    $c->req->params->{search_terms} = \@tags;
    $c->req->params->{browse_field} = 'tag';

    $c->forward( $c->controller('Browse')->action_for('journals') );
}


sub journals :Chained('base') :PathPart('journals') Args(0) {
    my ($self, $c) = @_;

    my $site_id = $c->stash->{current_site}->id;

    my $search = ref($c->req->params->{search_terms}) eq 'ARRAY' ? [@{$c->req->params->{search_terms}}] : [$c->req->params->{search_terms}];
    my $browse_field = $c->stash->{browse_field} = $c->req->params->{browse_field};

    my $start_record = 0;
    my $per_page;

    my $search_details = $c->session->{search_details}->{$c->stash->{current_site}->id}->{$browse_field}->{join '+', @$search};
    if (defined($search_details)) {
        $start_record = $c->req->params->{start_record} || 0;
        $per_page = $search_details->{per_page};
    }

    my ($journals, $browse_type);
    if ($browse_field eq 'subject') {
        @$search = map { CUFTS::CJDB::Util::strip_title($_) } @$search;
        $journals = CJDB::DB::Journals->search_distinct_by_exact_subjects($site_id, $search, $start_record, $per_page);
    } elsif ($browse_field eq 'association') {
        @$search = map { CUFTS::CJDB::Util::strip_title($_) } @$search;
        $journals = CJDB::DB::Journals->search_distinct_by_exact_associations($site_id, $search, $start_record, $per_page);
    } elsif ($browse_field eq 'tag') {
        @$search = map { CUFTS::CJDB::Util::strip_tag($_) } map {split /,/} @$search;

        # If a viewing level has not been defined, check the local param for local search only,
        # or default to public + local (3).

        my $viewing =   defined($c->req->params->{viewing})
                      ? $c->req->params->{viewing}
                      : $c->req->params->{local}
                      ? 2 
                      : 3;

          # Add account to the parameters so that /browse/bytags will search on only that account

          if ( !hascontent( $c->req->params->{account} ) && defined( $c->stash->{current_account} ) ) {
              $c->req->params->{account} = $c->stash->{current_account}->id;
          }

        $journals = CJDB::DB::Journals->search_distinct_by_tags($search, $start_record, $per_page, $c->req->params->{level}, $c->stash->{current_site}->id, $c->req->params->{account}, $viewing);
    } elsif ($browse_field eq 'issn') {
        $journals = CJDB::DB::Journals->search_by_issn($site_id, $search, 1, $start_record, $per_page);
    } else {
        die("Inavlid browse field: $browse_field");
    }

    # Build search cache information

    unless ($search_details) {
        $search_details->{count} = scalar(@$journals);
        $search_details->{per_page} = max( int(($search_details->{count} / $c->config->{default_max_columns}) + 1 ), $c->config->{default_min_per_page});
        $start_record = $c->req->params->{start_record} || 0;
            
        # Build list of start/end titles and indexes
    
        my $x = 0;
        while ($x < $search_details->{count}) {
            my $y = min( ($x + $search_details->{per_page} - 1), ($search_details->{count} - 1) );
            push @{$search_details->{indexes}}, [$x, $journals->[$x]->title, $journals->[$y]->title];
            $x += $search_details->{per_page};
        }

        my $slice_max = min($#$journals, ($start_record + $search_details->{per_page} - 1));
        @$journals = @$journals[$start_record .. $slice_max];

        $c->session->{search_details}->{$c->stash->{current_site}->id}->{$browse_field}->{join '+', $search} = $search_details;
    }

    $c->stash->{search_details} = $search_details;
    $c->stash->{start_record} = $start_record;
    $c->stash->{records} = $journals;
    $c->stash->{search_terms} = ref($c->req->params->{search_terms}) eq 'ARRAY' ? $c->req->params->{search_terms} : [$c->req->params->{search_terms}];
    $c->stash->{browse_type} = 'journals';
    $c->stash->{show_unified} = $c->stash->{current_site}->cjdb_unified_journal_list eq 'unified' ? 1 : 0;

    $c->stash->{template} = 'browse_journals.tt';
    
    if ( defined($c->req->params->{format}) && $c->req->params->{format} eq 'json' ) {
        $c->stash->{json} = {
            total_count     => int($search_details->{count}),
            start_record    => int($start_record),
            page_count      => int($search_details->{per_page}),
            journals        => [ map { $self->journal_object_to_hash($c, $_) } @$journals ],
        };
        $c->forward('View::JSON');
    }
    
}

sub titles :Chained('base') :PathPart('titles') Args(0) {
    my ($self, $c) = @_;

    my $site_id = $c->stash->{current_site}->id;
    my $search_term = $c->req->params->{search_terms};  # Only one term when searching titles
    my $search_type = $c->stash->{search_type} = $c->req->params->{search_type};

    my $start_record = 0;
    my $per_page = $c->req->params->{per_page};

    my $search_details = $c->session->{search_details}->{$c->stash->{current_site}->id}->{title}->{$search_type}->{$search_term};
    if (defined($search_details)) {
        $start_record = $c->req->params->{start_record} || 0;
        $per_page ||= $search_details->{per_page};
    }

    my $titles;

    if ($search_type eq 'startswith') {
        my $tmp_search_term = CUFTS::CJDB::Util::strip_articles($search_term);
        $tmp_search_term = CUFTS::CJDB::Util::strip_title($tmp_search_term);
        $tmp_search_term .= '%';
        $titles = CJDB::DB::Journals->search_distinct_title_by_journal_main($site_id, $tmp_search_term, $start_record, $per_page);
    } elsif ($search_type eq 'advstartswith') {
        my $tmp_search_term = CUFTS::CJDB::Util::strip_articles($search_term);
        $tmp_search_term = lc($tmp_search_term);
        $tmp_search_term = "^${search_term}.*";
        $titles = CJDB::DB::Journals->search_re_distinct_title_by_journal_main($site_id, $tmp_search_term, $start_record, $per_page);
    } elsif ($search_type eq 'exact') {

        # Should exact title searches strip articles?

        my $tmp_search_term = CUFTS::CJDB::Util::strip_articles($search_term);
        $tmp_search_term = CUFTS::CJDB::Util::strip_title($tmp_search_term);
        $titles = CJDB::DB::Journals->search_distinct_title_by_journal_main($site_id, $tmp_search_term, $start_record, $per_page);
    } elsif ($search_type eq 'any') {
        my $tmp_search_term = CUFTS::CJDB::Util::strip_articles($search_term);
        $tmp_search_term = CUFTS::CJDB::Util::strip_title($tmp_search_term);
        my @search_terms = split / /, $tmp_search_term;
    
        $titles = CJDB::DB::Journals->search_distinct_title_by_journal_main_any($site_id, \@search_terms, $start_record, $per_page);
    } elsif ($search_type eq 'all') {
        my $tmp_search_term = CUFTS::CJDB::Util::strip_articles($search_term);
        $tmp_search_term = CUFTS::CJDB::Util::strip_title($tmp_search_term);
        my @search_terms = split / /, $tmp_search_term;

        $titles = CJDB::DB::Journals->search_distinct_title_by_journal_main_all($site_id, \@search_terms, $start_record, $per_page);
    } else {
        die("Unrecognized title search type: " . Dumper($search_type) );
    }

    # Build search cache information

    unless ($search_details) {
        $search_details->{count} = scalar(@$titles);
        $search_details->{per_page} = max( int(($search_details->{count} / $c->config->{default_max_columns}) + 1 ), $c->config->{default_min_per_page});
        $start_record = $c->req->params->{start_record} || 0;
            
        # Build list of start/end titles and indexes

        my $x = 0;
        while ($x < $search_details->{count}) {
            my $y = min( ($x + $search_details->{per_page} - 1), ($search_details->{count} - 1) );
            push @{$search_details->{indexes}}, [$x, $titles->[$x]->result_title, $titles->[$y]->result_title];
            $x += $search_details->{per_page};
        }

        my $slice_max = min( $#$titles, ($start_record + $search_details->{per_page} - 1) );    
        @$titles = @$titles[$start_record .. $slice_max];

        $c->session->{search_details}->{$c->stash->{current_site}->id}->{title}->{$search_type}->{$search_term} = $search_details;
    }

    $c->stash->{search_details} = $search_details;
    $c->stash->{records}        = $titles;
    $c->stash->{start_record}   = $start_record;
    $c->stash->{browse_type}    = 'titles';
    $c->stash->{browse_field}   = 'title';
    $c->stash->{search_terms}   = [ $c->req->params->{search_terms} ];
    $c->stash->{show_unified}   = $c->stash->{current_site}->cjdb_unified_journal_list eq 'unified' ? 1 : 0;

    $c->stash->{template} = 'browse_journals.tt';

    if ( defined($c->req->params->{format}) && $c->req->params->{format} eq 'json' ) {
        $c->stash->{json} = {
            total_count     => int($search_details->{count}),
            start_record    => int($start_record),
            page_count      => int($search_details->{per_page}),
            journals        => [ map { $self->journal_object_to_hash($c, $_) } @$titles ],
        };
        $c->forward('View::JSON');
    }

}

sub titles_new :Chained('base') :PathPart('titles_new') Args(0) {
    my ($self, $c) = @_;

    my $site_id = $c->stash->{current_site}->id;
    my $search_term = $c->req->params->{search_terms};  # Only one term when searching titles
    my $search_type = $c->stash->{search_type} = $c->req->params->{search_type};
    
    my $start_page   = $c->req->params->{page} || 1;
    my $per_page     = $c->req->params->{per_page} || 50;    # TODO: Customize this per site 
    
    my ( $titles, $count );
    if ($search_type eq 'startswith') {
        my $tmp_search_term = CUFTS::CJDB::Util::strip_articles($search_term);
        $tmp_search_term = CUFTS::CJDB::Util::strip_title($tmp_search_term);
        $tmp_search_term .= '%';
        $count  = CJDB::DB::Journals->count_distinct_title_by_journal_main($site_id, $tmp_search_term); 
        $titles = CJDB::DB::Journals->search_distinct_title_by_journal_main($site_id, $tmp_search_term, (($start_page-1)*$per_page), $per_page);
    }
    elsif ($search_type eq 'ft' ) {
        my $tmp_search_term = CUFTS::CJDB::Util::strip_articles($search_term);
        $tmp_search_term = CUFTS::CJDB::Util::strip_title($tmp_search_term);
        $count  = CJDB::DB::Journals->count_distinct_title_by_journal_main_ft($site_id, $tmp_search_term); 
        $titles = CJDB::DB::Journals->search_distinct_title_by_journal_main_ft($site_id, $tmp_search_term, (($start_page-1)*$per_page), $per_page);
    }

    if ( $c->req->params->{format} eq 'json' ) {
        $c->stash->{json} = {
            total_count     => $count,
            start_record    => (($start_page-1)*$per_page),
            page_count      => $per_page,
            journals        => [ map { $self->journal_object_to_hash($c, $_) } @$titles ],
        };
        return $c->forward('View::JSON');
    }
    
    my $pager = Data::Page->new();
    $pager->total_entries( $count );
    $pager->entries_per_page( $per_page );
    $pager->current_page( $start_page );
    
    $c->stash->{records}        = $titles;
    $c->stash->{pager}          = $pager;
    $c->stash->{browse_type}    = 'titles';
    $c->stash->{browse_field}   = 'title';
    $c->stash->{search_terms}   = [ $c->req->params->{search_terms} ];
    $c->stash->{show_unified}   = $c->stash->{current_site}->cjdb_unified_journal_list eq 'unified' ? 1 : 0;
    $c->stash->{template} = 'browse_journals_new.tt';
}

sub journal_object_to_hash {
    my ( $self, $c, $journal ) = @_;
    return {
        title        => $journal->result_title || $journal->title,
        url          => $c->stash->{url_base} . '/journal/' . $journal->journals_auth->id,
        journal_auth => $journal->journals_auth->id,
        issns        => defined($journal->issns) ? [ map { $_->issn } $journal->issns ] : undef,
    };
}


sub subjects :Chained('base') :PathPart('subjects') Args(0) {
    my ($self, $c) = @_;

    my $site_id = $c->stash->{current_site}->id;

    my $search_term = $c->req->params->{search_terms};
    my $search_type = $c->req->params->{search_type};
    $search_term = CUFTS::CJDB::Util::strip_title($search_term);

    my $subjects;

    if ($search_type eq 'startswith') {
        $search_term .= '%';
        @$subjects = CJDB::DB::Subjects->search_distinct($site_id, $search_term);
    } elsif ($search_type eq 'exact') {
        @$subjects = CJDB::DB::Subjects->search_distinct($site_id, $search_term);
    } elsif ($search_type eq 'any') {
        my @search_terms = split / /, $search_term;
        $subjects = CJDB::DB::Subjects->search_distinct_union($site_id, @search_terms);
    } elsif ($search_type eq 'all') {
        my @search_terms = split / /, $search_term;
        $subjects = CJDB::DB::Subjects->search_distinct_intersect($site_id, @search_terms);
    } else {
        die("Unrecognized subject search type: $search_type");
    }

    $c->stash->{subjects}     = $subjects;
    $c->stash->{search_terms} = $c->req->params->{search_terms};
    $c->stash->{search_type}  = $c->req->params->{search_type};

    $c->stash->{template} = 'browse_subjects.tt';
}

sub associations :Chained('base') :PathPart('associations') Args(0) {
    my ($self, $c) = @_;

    my $site_id = $c->stash->{current_site}->id;

    my $search_term = $c->req->params->{search_terms};
    my $search_type = $c->req->params->{search_type};
    $search_term = CUFTS::CJDB::Util::strip_title($search_term);

    my $associations;

    if ($search_type eq 'startswith') {
        $search_term .= '%';
        @$associations = CJDB::DB::Associations->search_distinct($site_id, $search_term);
    } elsif ($search_type eq 'exact') {
        @$associations = CJDB::DB::Associations->search_distinct($site_id, $search_term);
    } elsif ($search_type eq 'any') {
        my @search_terms = split / /, $search_term;
        $associations = CJDB::DB::Associations->search_distinct_union($site_id, @search_terms);
    } elsif ($search_type eq 'all') {
        my @search_terms = split / /, $search_term;
        $associations = CJDB::DB::Associations->search_distinct_intersect($site_id, @search_terms);
    } else {
        die("Unrecognized association search type: $search_type");
    }

    $c->stash->{associations} = $associations;
    $c->stash->{search_terms} = $c->req->params->{search_terms};
    $c->stash->{search_type}  = $c->req->params->{search_type};
    $c->stash->{template}     = 'browse_associations.tt';
}



sub show :Chained('base') :PathPart('show') Args(0) {
    my ($self, $c) = @_;

    my $browse_field  = $c->req->params->{browse_field};
    my $search_term   = $c->req->params->{search_terms};
    my $search_type   = $c->req->params->{search_type};
    
    if ( !defined($search_term) || ( !ref($search_term) && $search_term eq '' ) ) {
        $c->stash->{empty_search} = 'Please enter a search term.';
        return $c->forward( $c->controller('Browse')->action_for('browse') );
    }

    if ($browse_field eq 'title') {
        if ( $search_type eq 'ft' ) {
            return $c->forward('/browse/titles_new');
        }
        return $c->forward('/browse/titles');
    } elsif ($browse_field eq 'title_new') {
        return $c->forward('/browse/titles_new');
    } elsif ($browse_field eq 'subject') {
        return $c->forward('/browse/subjects');
    } elsif ($browse_field eq 'association') {
        return $c->forward('/browse/associations');
    } elsif ($browse_field eq 'issn') {
        return $c->forward('/browse/journals');
    } elsif ($browse_field eq 'tag') {
        return $c->forward('/browse/journals');
    }

    die('Invalid browse_field value: ' . Dumper($browse_field) );
}


sub ajax_title :Chained('base') :PathPart('ajax_title') Args(0) {
    my ( $self, $c ) = @_;

    my $string = $c->req->params->{search_terms};
    my $response = '';

    if ( hascontent($string) ) {
        my $titles = CJDB::DB::Titles->search_titlelist( $c->stash->{current_site}->id, "$string%" );
        foreach my $title (@$titles) {
            $response .= "<li>$title->[0]</li>\n";
        }
    }

    $c->response->body("<ul>$response</ul>\n");
    $c->response->content_type('text/html; charset=iso-8859-1');
}


sub ajax_issn :Chained('base') :PathPart('ajax_issn') Args(0) {
    my ( $self, $c ) = @_;

    my $string = $c->req->params->{search_terms};
    my $response = '';

    if ( hascontent($string) ) {
        $string = uc($string);
        my $issns = CJDB::DB::ISSNs->search_issnlist( $c->stash->{current_site}->id, "$string%" );
        foreach my $issn (@$issns) {
            $response .= '<li>' . dashed_issn($issn->[0]) . '<span class="informal"> : ' . $issn->[1] . "</span></li>\n";
        }
    }

    $c->response->body("<ul>$response</ul>\n");
    $c->response->content_type('text/html; charset=iso-8859-1');
}

sub ajax_tag :Chained('base') :PathPart('ajax_tag') Args(0) {
    my ( $self, $c ) = @_;

    my $string = $c->req->params->{search_terms};
    my $response = '';

    if ( hascontent($string) ) {
        $string = lc($string);
        my $tags;
        if ( defined($c->stash->{current_account}) ) {
            $tags = CJDB::DB::Tags->search_taglist_account( $c->stash->{current_site}->id, $c->stash->{current_account}->id, "$string%" );
        } else {
            $tags = CJDB::DB::Tags->search_taglist_noaccount( $c->stash->{current_site}->id, "$string%" );
        }
        foreach my $tag (@$tags) {
            $response .= "<li>$tag->[0]</li>\n";
        }
    }

    $c->response->body("<ul>$response</ul>\n");
    $c->response->content_type('text/html; charset=iso-8859-1');
}

sub selected_journals :Chained('base') :PathPart('selected_journals') Args(0) {
    my ($self, $c) = @_;

    $c->stash->{template} = 'selected_journals.tt';
}


sub lcc :Chained('base') :PathPart('lcc') Args(0) {
    my ($self, $c) = @_;

    $c->stash->{template} = 'lcc_browse.tt';
}


sub max {
    my $max = shift;
    while (defined(my $val = shift)) {
        $val > $max and
            $max = $val;
    }

    return $max;
}

sub min {
    my $min = shift;
    while (defined(my $val = shift)) {
        $val < $min and
            $min = $val;
    }

    return $min;
}



=head1 AUTHOR

tholbroo

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
