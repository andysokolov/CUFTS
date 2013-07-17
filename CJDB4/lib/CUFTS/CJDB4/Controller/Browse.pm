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

    push @{$c->stash->{breadcrumbs}}, [ $c->uri_for_site( $c->controller('Browse')->action_for('browse') ), 'Journals' ];
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
            $cleaned_search_term = '^' . quotemeta $cleaned_search_term;
        }
        elsif ( $search_type eq 'advstartswith' ) {  # !!! No regex quoting, this is used internally
            $cleaned_search_term = '^' . lc(CUFTS::CJDB::Util::strip_articles($search_term)) . '.*';
        }

        $c->stash->{journals_rs} = $c->model('CUFTS::CJDBJournals')->search_distinct_title_by_journal_main( $site_id, $cleaned_search_term, $page, $rows );
    }

    $c->stash->{browse_form_tab} = 'title';
    $c->stash->{pager}           = $c->stash->{journals_rs}->pager;
    $c->stash->{template}        = 'browse_journals.tt';

    push @{$c->stash->{breadcrumbs}}, [ $c->uri_for_site( $c->controller('Browse')->action_for('titles') ), 'Titles' ];
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
        push @{$c->stash->{breadcrumbs}}, [ $c->uri_for_site( $c->controller('Browse')->action_for('bylink'), [ $type, $id ] ), 'By Subject' ];

    }
    elsif ( $type eq 'association' ) {
        $c->stash->{journals_rs} = $journals_rs->search( { 'journals_associations.association' => $id }, { join => [ 'journals_associations' ] } );
        $c->stash->{browse_type} = $type;
        $c->stash->{browse_value} = $c->model('CUFTS::CJDBAssociations')->find($id)->association;
        push @{$c->stash->{breadcrumbs}}, [ $c->uri_for_site( $c->controller('Browse')->action_for('bylink'), [ $type, $id ] ), 'By Association' ];
    }

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
    push @{$c->stash->{breadcrumbs}}, [ $c->uri_for_site( $c->controller('Browse')->action_for('subjects') ), 'Subjects' ];
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

    push @{$c->stash->{breadcrumbs}}, [ $c->uri_for_site( $c->controller('Browse')->action_for('associations') ), 'Associations' ];
}


sub tags :Chained('base') :PathPart('tags') :Args(0) {
    my ($self, $c) = @_;

    my $site_id     = $c->site->id;
    my $search_term = $c->req->params->{q};
    my $page        = $c->req->params->{page} || 1;
    my $rows        = $c->req->params->{per_page} || 50;    # TODO: Customize this per site
    my $level       = $c->req->params->{level};

    my @tags = map { CUFTS::CJDB::Util::strip_tag($_) } map {split /,/} $search_term;


    # If a viewing level has not been defined, check the local param for local search only,
    # or default to public + local (3).

    my $viewing =   defined($c->req->params->{viewing})  ? $c->req->params->{viewing}
                  : $c->req->params->{local}             ? 2
                  :                                        3;

    # Add account to the parameters so that /browse/bytags will search on only that account

    # if ( !hascontent( $c->req->params->{account} ) && defined( $c->stash->{current_account} ) ) {
    #     $c->req->params->{account} = $c->stash->{current_account}->id;
    # }

    if ( scalar(@tags) ) {

        my $rs = $c->model('CUFTS::CJDBJournals')->search_distinct_by_tags( \@tags, $level, $c->site, $c->account, $viewing );

        $rs = $rs->search({}, { page => $page, rows => $rows, order_by => 'stripped_sort_title' });

        $c->stash->{journals_rs} = $rs;
        $c->stash->{pager}       = $c->stash->{journals_rs}->pager;

    }
    else {
        $c->stash->{errors} = [ 'Empty search' ];
    }


    $c->stash->{browse_form_tab} = 'tag';
    $c->stash->{template}        = 'browse_journals.tt';

    push @{$c->stash->{breadcrumbs}}, [ $c->uri_for_site( $c->controller('Browse')->action_for('tags') ), 'By Tag' ];
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

        $c->stash->{journals_rs} = $rs;
        $c->stash->{pager}       = $c->stash->{journals_rs}->pager;

    }
    else {
        $c->stash->{errors} = [ 'Empty search' ];
    }

    $c->stash->{browse_form_tab} = 'issn';
    $c->stash->{template}        = 'browse_journals.tt';

    push @{$c->stash->{breadcrumbs}}, [ $c->uri_for_site( $c->controller('Browse')->action_for('issns') ), 'By ISSN' ];
}



=head1 AUTHOR

Todd Holbrook

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
