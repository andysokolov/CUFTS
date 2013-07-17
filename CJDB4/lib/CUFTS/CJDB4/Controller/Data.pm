package CUFTS::CJDB4::Controller::Data;
use Moose;
use namespace::autoclean;

use String::Util qw(hascontent);

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

CUFTS::CJDB4::Controller::Data - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 base

=cut

sub base :Chained('../site') :PathPart('data') :CaptureArgs(0) {
    my ( $self, $c ) = @_;
}

sub issns :Chained('base') :PathPart('issns') :Args(0) {
    my ( $self, $c ) = @_;

    my $site_id     = $c->site->id;
    my $search_term = uc($c->req->params->{q});
    my $page        = $c->req->params->{page} || 1;
    my $rows        = $c->req->params->{per_page} || 50;    # TODO: Customize this per site

    $search_term =~ tr/0-9X//cd;

    if ( hascontent($search_term) ) {

        if ( length $search_term < 8 ) {
            $search_term .= '%';
        }

        my $rs = $c->model('CUFTS::CJDBISSNs')->search(
            {
                'site'  => $site_id,
                'issn'  => { 'like' => $search_term },
            },
            {
                order_by     => 'issn',
            }
        );

		local $rs->result_source->schema->storage->dbh->{pg_server_prepare} = 0;  # Some LIKE searches are really slow on prepared statements
    	$c->stash->{json}->{total_count} = $rs->count;
        $c->stash->{json}->{results}     = [ map { $_->issn_dashed } $rs->search({}, { page => $page, rows => $rows })->all ];
    }
    else {
    	$c->stash->{json}->{results} = [];
    	$c->stash->{json}->{total_count} = 0;
    }

    $c->forward( 'View::JSON' );
}

sub tags :Chained('base') :PathPart('tags') :Args(0) {
    my ( $self, $c ) = @_;

    my $site_id     = $c->site->id;
    my $search_term = lc($c->req->params->{q});
    my $page        = $c->req->params->{page} || 1;
    my $rows        = $c->req->params->{per_page} || 50;    # TODO: Customize this per site

    if ( hascontent($search_term) ) {

        $search_term .= '%';

        my $rs = $c->model('CUFTS::CJDBTags')->search(
            {
                'site'  => $site_id,
                'tag'   => { 'like' => $search_term },
            },
            {
            	select		 => 'tag',
                order_by     => 'tag',
                distinct	 => 1,
            }
        );

		local $rs->result_source->schema->storage->dbh->{pg_server_prepare} = 0;  # Some LIKE searches are really slow on prepared statements
    	$c->stash->{json}->{total_count} = $rs->count;
        $c->stash->{json}->{results}     = [ map { $_->tag } $rs->search({}, { page => $page, rows => $rows })->all ];
    }
    else {
    	$c->stash->{json}->{results} = [];
    	$c->stash->{json}->{total_count} = 0;
    }

    $c->forward( 'View::JSON' );
}




=encoding utf8

=head1 AUTHOR

Todd Holbrook

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
