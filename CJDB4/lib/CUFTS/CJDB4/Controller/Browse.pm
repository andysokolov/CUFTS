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
	my $search_term = $c->req->params->{q};  # Only one term when searching titles
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
        elsif ( $search_type eq 'advstartswith' ) {  # !!! No RE quoting, this is used internally
            $cleaned_search_term = '^' . lc(CUFTS::CJDB::Util::strip_articles($search_term)) . '.*';
        }

        $c->stash->{journals_rs} = $c->model('CUFTS::CJDBJournals')->search_distinct_title_by_journal_main( $site_id, $cleaned_search_term, $page, $limit );
    }

    $c->stash->{pager}    = $c->stash->{journals_rs}->pager;
    $c->stash->{template} = 'browse_journals.tt';
}


=head1 AUTHOR

Todd Holbrook

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
