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

    push @{$c->stash->{breadcrumbs}}, [ $c->uri_for_site( $c->controller('Browse')->action_for('browse') ), $c->loc('Browse') ];
}

sub facet_options :Chained('/facet_options') :PathPart('browse') :CaptureArgs(0) {
    my ( $self, $c ) = @_;

    push @{$c->stash->{breadcrumbs}}, [ $c->uri_for_site( $c->controller('Browse')->action_for('browse') ), $c->loc('Browse') ];
}

=head2 browse_index

=cut

sub browse :Chained('facet_options') :PathPart('') :Args(0) {
    my ( $self, $c ) = @_;

    $c->stash->{template} = 'browse.tt';

    my %search = ( public_list => 't' );

    $self->_facets_from_params($c, \%search);

    my $empty = !exists $c->stash->{facets};

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
}

sub json :Chained('facet_options') :PathPart('json') :Args(0) {
    my ( $self, $c ) = @_;

    my %search = ( public_list => 't' );

    $self->_facets_from_params($c, \%search);

    my $empty = !exists $c->stash->{facets};

    my $rs = $c->model('CUFTS::ERMMain')->facet_search( $c->site->id, \%search, $empty ? 0 : undef );
    $rs = $rs->search({},{ '+select' => ['print_equivalents'], '+as' => ['print_equivalents'] });
    $rs->result_class('DBIx::Class::ResultClass::HashRefInflator');  # Get a hash so the JSON view can convert

    my @records = $rs->all();

    if ( exists( $c->stash->{facets}->{subject} ) ) {
        # Rank sort for subjects
        @records = sort { int($a->{rank} || 0) <=> int($b->{rank} || 0) or $a->{sort_name} cmp $b->{sort_name} } @records;
        # Put zeros at the end
        my $unranked = 0;
        foreach my $record ( @records ) {
            last if defined($record->{rank}) && $record->{rank} != 0;
            $unranked++;
        }
        push @records, splice @records, 0, $unranked;
    }
    else {
        # Default to title sort
        @records = sort { $a->{sort_name} cmp $b->{sort_name} } @records;
    }

    foreach my $record (@records) {

        # Add URL for record

        $record->{resource_url} = $c->uri_for_site( $c->controller('Resource')->action_for('resource'), [$record->{id}] )->as_string;

        # Add links to attached files if they exist

        my $files = $c->model('CUFTS::ERMFiles')->search({ linked_id => $record->{id}, link_type => 'm', description => { 'ilike' => '%public%' } } );
        $record->{files} = [];
        while ( my $file = $files->next ) {
            push @{ $record->{files} }, { description => $file->description, url => $c->uri_for_static( 'erm_files', 'm', $file->UUID . '.' . $file->ext )->as_string };
        }
    }


    $c->stash->{json}->{records} = \@records;
    $c->stash->{current_view}  = 'JSON';
}


sub facets_uri_redirect :Chained('base') :PathPart('facets') :Args {
    my ( $self, $c, @facets ) = @_;

    my $action = 'browse';
    if ( $facets[0] eq 'json' ) {
        shift @facets;
        $action = 'json';
    }

    my %facets;
    while ( my ( $type, $data ) = splice( @facets, 0, 2 ) ) {
        if ( $type eq 'id' ) {
            my @values = split ',', $data;
            $facets{$type} = [ @values ];
        }
        else {
            $facets{$type} = $data;
        }
    }

    $c->redirect( $c->uri_for_site( $c->controller->action_for($action), \%facets ) );
}

sub _facets_from_params {
    my ( $self, $c, $hash ) = @_;

    foreach my $param ( qw( resource_type resource_medium subject content_type name keyword name_exact_keyword license_generic_boolean vendor publisher subscription_status license_allows_walkins open_access provider ) ) {
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
