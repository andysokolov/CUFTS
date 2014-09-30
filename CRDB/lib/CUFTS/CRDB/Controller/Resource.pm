package CUFTS::CRDB::Controller::Resource;

use strict;
use warnings;
use base 'Catalyst::Controller';

use String::Util qw(trim hascontent);

=head1 NAME

CUFTS::CRDB::Controller::Resource - Catalyst Controller for working with an individual ERM resource

=head1 DESCRIPTION

Catalyst Controller

=head1 METHODS

=cut

sub base : Chained('/site') PathPart('resource') CaptureArgs(0) { }

sub load_resource : Chained('base') PathPart('') CaptureArgs(1) {
    my ( $self, $c, $resource_id ) = @_;

    $c->stash->{erm} = $c->model('CUFTS::ERMMain')->search({ id => $resource_id, site => $c->site->id })->first();
}

sub goto : Chained('load_resource') PathPart('goto') Args(0) {
    my ( $self, $c ) = @_;

    my $erm = $c->stash->{erm};

    $c->model('CUFTS::ERMUses')->create({ erm_main => $erm->id }); # count click

    $c->response->redirect( hascontent($erm->url) ? $erm->proxied_url( $c->site ) : $c->uri_for_site( $c->controller('Resource')->action_for('default_view'), [ $erm->id ] ) );
    $c->detach();
}


=head2 default_view

Default is to view the resource.

=cut

sub default_view : Chained('load_resource') PathPart('') Args(0) {
    my ( $self, $c ) = @_;

    if ( defined($c->stash->{erm}->public) && $c->stash->{erm}->public == 0 && !$c->check_user_roles('staff') ) {
        return $c->forward('not_public');
    }

    $c->save_current_action();

    # Create links to subject searches
    $c->stash->{subject_links} = [ map { [ $_->subject, $c->uri_for_site( $c->controller('Browse')->action_for('html_facets'), 'subject', $_->id, {} ) ] }
                                    sort { $a->subject cmp $b->subject } $c->stash->{erm}->subjects ];

    $c->stash->{display_fields} = [ $c->model('CUFTS::ERMDisplayFields')->search( { site => $c->site->id }, { order_by => 'display_order' } )->all ];

    $c->stash->{template} = 'resource.tt';
}


=head2 not_public

Display a message that this resource is not public

=cut

sub not_public : Private {
    my ( $self, $c ) = @_;

    $c->stash->{template} = 'resource_not_public.tt';
}

=head2 json

Packages up a bunch of information about the resource, and returns it in JSON.  This is
used for things like the pop-up resource details.

=cut


sub json : Chained('load_resource') PathPart('json') Args(0) {
    my ( $self, $c ) = @_;

    die('Disabled JSON view of resources until some control of what data is dumped can be added for security reasons.');

    my $erm_obj = $c->stash->{erm};
    my $erm_hash = {
        subjects => [],
        content_types => [],
    };

    # TODO: Get valid staff and patron columns and filter

    foreach my $column ( $erm_obj->columns() ) {
        $erm_hash->{$column} = $erm_obj->$column();
    }
    foreach my $column ( qw( consortia cost_base resource_medium resource_type ) ) {
        if ( defined( $erm_hash->{$column} ) ) {
            $erm_hash->{$column} = $erm_obj->$column()->$column();
        }
    }

    my @subjects = $erm_obj->subjects;
    @{ $erm_hash->{subjects} } = map { $_->subject } sort { $a->subject cmp $b->subject } @subjects;

    my @content_types = $erm_obj->content_types;
    @{ $erm_hash->{content_types} } = map { $_->content_type } sort { $a->content_type cmp $b->content_type } @content_types;

    if ( my $license = $erm_hash->{license} ) {
        $erm_hash->{license} = {};
        foreach my $column ( $license->columns() ) {
            $erm_hash->{license}->{$column} = $license->$column();
        }
    }

    if ( defined($erm_hash->{provider}) ) {
        $erm_hash->{provider} = $erm_hash->{provider}->provider_name;
    }

    $c->stash->{json} = $erm_hash;

    $c->stash->{current_view} = 'JSON';
}

=head1 AUTHOR

Todd Holbrook

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
