package CUFTS::CRDB4::Controller::Browse;
use Moose;
use namespace::autoclean;

use String::Util qw( trim hascontent );

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

CUFTS::CRDB4::Controller::Browse - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub base :Chained('/site') :PathPart('browse') :CaptureArgs(0) {
    my ( $self, $c ) = @_;
}

sub facet_options :Chained('/facet_options') :PathPart('browse') :CaptureArgs(0) {}

=head2 browse_index

=cut

sub browse :Chained('facet_options') :PathPart('') :Args(0) {
    my ( $self, $c ) = @_;

    $c->stash->{template} = 'browse.tt';

    my %search = ( public_list => 't' );

    $self->_facets_from_params($c, \%search);

    my $empty = !exists $c->stash->{facets};

    # if ( !$empty || hascontent($q) ) {

        my $rs = $c->model('CUFTS::ERMMain')->facet_search( $c->site->id, \%search, $empty ? 0 : undef );
        my @records = $rs->all();

        if ( exists( $c->stash->{facets}->{subject} ) ) {
            # Rank sort for subjects
            @records = sort { int($a->rank || 0) <=> int($b->rank || 0) or $a->sort_name cmp $b->sort_name } @records;
            # Put zeros at the end
            my $unranked = 0;
            foreach my $record ( @records ) {
                last if defined($record->rank) && $record->rank != 0;
                $unranked++;
            }
            push @records, splice @records, 0, $unranked;

            # Put the subject into the stash in case we need the subject description
            $c->stash->{subject_description} = $c->model('CUFTS::ERMSubjects')->find( $c->stash->{facets}->{subject} )->description;

        }
        else {
            # Default to title sort
            @records = sort { $a->sort_name cmp $b->sort_name } @records;
        }

        $c->stash->{records}  = \@records;

    # }
}




sub _facets_from_params {
    my ( $self, $c, $hash ) = @_;

    foreach my $param ( qw( resource_type resource_medium subject content_type name keyword ) ) {
        my $val = $c->request->params->{$param};
        next if !hascontent($val);

        # Special case name
        if ( $param eq 'name' && $val eq '0-9' ) {
            $hash->{name_regex} = '^[0-9]';
        }
        else {
            $hash->{$param} = $val;
        }

        $c->stash->{facets}->{$param} = $val;
    }
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
