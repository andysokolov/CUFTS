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
	my $limit       = $c->req->params->{per_page} || 50;    # TODO: Customize this per site

	my $cleaned_search_term = CUFTS::CJDB::Util::strip_title( CUFTS::CJDB::Util::strip_articles($search_term) );

    if ( $search_type eq 'ft' ) {
        $c->stash->{journals_rs} = $c->model('CUFTS::CJDBJournals')->search_distinct_title_by_journal_main_ft( $site_id, $cleaned_search_term, $page, $limit );
    }
    else {
        if ( $search_type eq 'startswith' ) {
            $cleaned_search_term = '^' . quotemeta $cleaned_search_term;
        }
        elsif ( $search_type eq 'advstartswith' ) {  # !!! No regex quoting, this is used internally
            $cleaned_search_term = '^' . lc(CUFTS::CJDB::Util::strip_articles($search_term)) . '.*';
        }

        $c->stash->{journals_rs} = $c->model('CUFTS::CJDBJournals')->search_distinct_title_by_journal_main( $site_id, $cleaned_search_term, $page, $limit );
    }

    $c->stash->{browse_form_tab} = 'title';
    $c->stash->{pager}           = $c->stash->{journals_rs}->pager;
    $c->stash->{template}        = 'browse_journals.tt';
}

sub bylink :Chained('base') :PathPart('bylink') :Args(2) {
    my ($self, $c, $type, $id) = @_;

    my $page  = $c->req->params->{page} || 1;
    my $limit = $c->req->params->{per_page} || 50;    # TODO: Customize this per site

    my $journals_rs = $c->model('CUFTS::CJDBJournals')->search(
        {
            'me.site' => $c->site->id,
        },
        {
            page => $page,
            rows => $limit,
            order_by => 'stripped_sort_title',
        }
    );

    if ( $type eq 'subject' ) {
        $c->stash->{journals_rs} = $journals_rs->search( { 'journals_subjects.subject' => $id }, { join => [ 'journals_subjects' ] } );
        $c->stash->{browse_type} = $type;
        $c->stash->{browse_value} = $c->model('CUFTS::CJDBSubjects')->find($id)->subject;
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
    my $limit       = $c->req->params->{per_page} || 50;    # TODO: Customize this per site

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
            rows         => $limit,
            order_by     => 'subject',
        }
    );

    $c->stash->{browse_form_tab} = 'subject';
    $c->stash->{pager}           = $c->stash->{subjects_rs}->pager;
    $c->stash->{template}        = 'browse_subjects.tt';
}

=head1 AUTHOR

Todd Holbrook

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
