package CUFTS::CRDB::Controller::Mobile;

use strict;
use warnings;
use base 'Catalyst::Controller';

use URI::Escape;
use Unicode::String qw(utf8);

use JSON::XS qw(encode_json);
use CUFTS::Util::Simple;
use HTML::Strip;

=head1 NAME

CUFTS::CRDB::Controller::Mobile - Catalyst Controller for a mobile interface

=head1 DESCRIPTION

Catalyst Controller

=head1 METHODS

=cut

sub base : Chained('/site') PathPart('m') CaptureArgs(0) {
    my ( $self, $c ) = @_;


    $c->stash->{sandbox} = $c->session->{sandbox};
    my $box = $c->session->{sandbox} ? 'sandbox' : 'active';

    # Set up site specific CSS file if it exists
    my $site_css = '/sites/' . $c->site->id . "/static/css/${box}/crdb_mobile.css";

    if ( -e ($c->config->{root} . $site_css) ) {
        $c->stash->{site_css_file} = $c->uri_for( $site_css );
    }

    $c->stash->{current_view} = 'TTMobile';
}


=head2 browse_index

=cut

sub browse_sencha : Chained('base') PathPart('sencha_test') Args(0) {
    my ( $self, $c ) = @_;

    $c->stash->{template} = 'mobile_app_sencha_test.tt';
}

sub browse_j : Chained('base') PathPart('') Args(0) {
    my ( $self, $c ) = @_;

    $c->stash->{template} = 'mobile_app.tt';
}

sub subjects_json : Chained('base') PathPart('subjects') Args(0) {
    my ( $self, $c ) = @_;

    my $rs = $c->model('CUFTS::ERMSubjects')->search({ site => $c->site->id }, { order_by => 'subject' } );
    $rs->result_class('DBIx::Class::ResultClass::HashRefInflator');  # Don't really need objects

    $c->stash->{json}->{subjects} = [ map { { value => $_->{id}, text => $_->{subject} } } $rs->all ];
    $c->stash->{current_view}  = 'JSON';
}

sub resource_json : Chained('base') PathPart('resource') Args(0) {
    my ( $self, $c ) = @_;

    my $resource_id    = $c->request->params->{resource_id};
    my $resource       = $c->model('CUFTS::ERMMain')->search({ id => $resource_id, site => $c->site->id })->first();
    my @display_fields = $c->model('CUFTS::ERMDisplayFields')->search( { site => $c->site->id, staff_view => { '!=' => 'true' } }, { order_by => 'display_order' } )->all;


    my $resource_hash = $resource->to_hash(\@display_fields);

    $c->stash->{json}->{resource} = $resource_hash;
    $c->stash->{json}->{display_fields} = [ map { { field => $_->field, type => $_->field_type } } @display_fields ];
    $c->stash->{current_view}  = 'JSON';
}

sub resources_json : Chained('base') PathPart('resources') Args(0) {
    my ( $self, $c ) = @_;

    my $html_strip = HTML::Strip->new();

    my $subject = $c->request->params->{'subject'};
    my $name = $c->request->params->{'name'};

    my $search = {
        public_list => 't',
    };
    if ( $subject ) {
        $search->{subject} = $subject;
    }
    elsif ( $name ) {
        if ( $name eq '#' ) {
            $search->{name_regex} = '^[^a-zA-Z]';
        }
        else {
            $search->{name} = $name;
        }
    }

    my $rs = $c->model('CUFTS::ERMMain')->facet_search( $c->site->id, $search );
    $rs->result_class('DBIx::Class::ResultClass::HashRefInflator');  # Don't really need objects
    my @resources = $rs->all();

    if ( $subject ) {
        # Rank sort for subjects
        @resources = sort { int($a->{rank}) <=> int($b->{rank}) or $a->{sort_name} cmp $b->{sort_name} } @resources;
        # Put zeros at the end
        my $unranked = 0;
        foreach my $resource ( @resources ) {
            last if $resource->{rank} != 0;
            $unranked++;
        }
        push @resources, splice @resources, 0, $unranked;
    }
    else {
        # Default to title sort
        @resources = sort { $a->{sort_name} cmp $b->{sort_name} } @resources;
    }

    foreach my $resource (@resources) {
        $resource->{name} = delete $resource->{result_name};

        if ( $subject ) {
            $resource->{group} = $resource->{rank} == 0 ? 'Other Resources' : 'Top Resources';
        }
        else {
            my $first_char = substr($resource->{name},0,1);
            $first_char = uc( CUFTS::Util::Simple::convert_diacritics($first_char) );
            $resource->{group} = $first_char =~ /^[A-Z]/ ? $first_char : '#';
        }

        $resource->{description_brief} = $html_strip->parse( $resource->{description_brief} );
        $html_strip->eof;

        # Remove some things we don't need to cut down on data sent.
        foreach my $field ( qw( key sort_name vendor license proxy distinct_erm_main  ) ) {
            delete $resource->{$field};
        }

    }

    $c->stash->{json}->{resources} = \@resources;
    $c->stash->{current_view}  = 'JSON';
}



=head1 AUTHOR

Todd Holbrook

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
