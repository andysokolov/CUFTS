package CUFTS::CRDB4::Controller::Resource;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

CUFTS::CRDB4::Controller::Resource - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub base :Chained('/site') :PathPart('resource') :CaptureArgs(0) {}

sub load_resource :Chained('base') :PathPart('') :CaptureArgs(1) {
    my ( $self, $c, $resource_id ) = @_;

    if ( $c->has_account && $c->account->has_role('edit_erm_records') ) {
        $c->stash->{editing_enabled} = 1;
        if ( exists $c->stash->{facets} && exists $c->stash->{facets}->{subject} && scalar(keys(%{$c->stash->{facets}})) == 1 ) {
            $c->stash->{sorting_enabled} = 1;
        }
    }

    my $erm = $c->model('CUFTS::ERMMain')->find({
        id          => $resource_id,
        site        => $c->site->id,
        public_list => 't',
    });

    $c->stash->{erm} = $erm;
    push @{$c->stash->{breadcrumbs}}, [ $c->uri_for_site( $c->controller('Resource')->action_for('resource'), [ $resource_id ] ), $erm->main_name ];
}

sub goto : Chained('load_resource') PathPart('goto') Args(0) {
    my ( $self, $c ) = @_;

    $c->stash->{erm}->add_to_uses({});  # Add click count

    $c->response->redirect( $c->stash->{erm}->proxied_url( $c->site ) );
    $c->detach();
}

sub resource :Chained('load_resource') :PathPart('') :Args(0) {
    my ( $self, $c ) = @_;

    # Create links to subject searches
    $c->stash->{subject_links} = [ map { [ $_->subject, $c->uri_for_site( $c->controller('Browse')->action_for('browse'), { subject => $_->id } ) ] }  
                                    sort { $a->subject cmp $b->subject } $c->stash->{erm}->subjects ];

    $c->stash->{display_fields} = [
        $c->model('CUFTS::ERMDisplayFields')->search( { site => $c->site->id }, { order_by => 'display_order' } )->all
    ];

    $c->stash->{template} = 'resource.tt';
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
