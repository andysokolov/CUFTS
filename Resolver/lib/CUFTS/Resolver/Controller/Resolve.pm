package CUFTS::Resolver::Controller::Resolve;

use strict;
use warnings;
use base 'Catalyst::Controller';

use CUFTS::Util::Simple;
use CUFTS::ResourcesLoader;
use CUFTS::Resolve;
use CUFTS::Request;

sub base : Chained('/site') PathPart('resolve') CaptureArgs(0) {
    my ( $self, $c ) = @_;

    # FUTURE: Consider adding load of site specific resolver?
    my $resolver = new CUFTS::Resolve();
    $resolver->schema( $c->model('CUFTS')->schema );
    my $sites = $resolver->get_sites( undef, [ $c->site->key, defined($c->stash->{other_sites}) ? @{$c->stash->{other_sites}} : () ] );

    $c->stash->{sites}    = $sites;
    $c->stash->{resolver} = $resolver;
}

sub openurl : Chained('base') PathPart('openurl') Args() {
    my ( $self, $c, $template ) = @_;

    my $params   = $c->req->params;
    my $resolver = $c->stash->{resolver};
    my $sites    = $c->stash->{sites};

    # Strip anything weird from the template name
    if ( defined($template) ) {
        $template =~ tr/-a-zA-Z0-9_//cd;
    }

    # parse request as an OpenURL (could be 0.1 or 1.0)
    my $request = CUFTS::Request->parse_openurl($params);

    # if we didn't get the sites from the URL earlier, try the request.
    if ( !scalar( @{$sites} ) ) {
        $sites = $resolver->get_sites($request);
    }

    # resolve the request
    my $results = $resolver->resolve( $sites, $request );

    $c->stash->{results}  = $results;
    $c->stash->{request}  = $request;
    $c->stash->{template} = $template ? "${template}.tt" : 'main.tt';
}

=back

=head1 NAME

CUFTS::Resolver::C::Resolve - Catalyst component

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
