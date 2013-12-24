package CUFTS::Resolver::Controller::Test;

use strict;
use warnings;
use base 'Catalyst::Controller';

use CUFTS::Util::Simple;
use URI;

sub base : Chained('/base') PathPart('test') CaptureArgs(0) {}

# default - test screen view listing all sites and
# templates with fields to be sent to the resolver.

sub test : Chained('base') PathPart('') Args(0) {
    my ( $self, $c ) = @_;

    my @sites = $c->model('CUFTS::Sites')->search({}, { order_by => 'name' })->all();
    $c->stash->{sites}    = \@sites;
    $c->stash->{template} = 'test.tt';

    return;
}

# do - process a test request, turn it into a URL to
# send to the resolver and redirect to that URL

sub do : Chained('base') PathPart('do') Args(0) {
    my ( $self, $c ) = @_;

    my $params = $c->req->params;

    my $psite     = delete $params->{_site};
    my $ptemplate = delete $params->{_template};
    delete $params->{_submit};

    my $uri;
    if ( not_empty_string($psite) ) {
        my $site = $c->model('CUFTS::Sites')->find({ key => $psite });
        $uri = $c->uri_for_given_site( $c->controller('Resolve')->action_for('openurl'), $site, $ptemplate, $params );
    }
    else {
        $uri = $c->uri_for_site( $c->controller('Resolve')->action_for('openurl'), $ptemplate, $params );
    }

    return $c->redirect($uri);
}

=back

=head1 NAME

CUFTS::Resolver::C::Test - Catalyst component

=head1 SYNOPSIS

See L<CUFTS::Resolver>

=head1 DESCRIPTION

Catalyst component.

=head1 AUTHOR

A clever guy

=head1 LICENSE

This library is free software . You can redistribute it and/or modify
it under the same terms as perl itself.

=cut

1;
