package CUFTS::Resolver;

use strict;

use Catalyst::Runtime '5.70';

use Catalyst qw/
    -Debug
    ConfigLoader
    Static::Simple
/;

use lib '../lib';
use CUFTS::Config;

our $VERSION = '2.00.00';

__PACKAGE__->config(
    name       => 'CUFTS::Resolver',
);

__PACKAGE__->setup;

__PACKAGE__->mk_accessors( qw( site ) );


sub redirect {
    my ( $c, $uri ) = @_;
    
    $c->res->redirect( $uri );
    $c->detach();
}


sub uri_for_given_site {
    my ( $c, $url, $site, $caps, @rest ) = @_;

    my $captures_copy = [];

    # use Data::Dumper;
    # warn( "\nurl: " . Dumper($url) );
    # warn( "\ncaps: " . Dumper($caps) );
    # warn( "\nrest: " . Dumper(\@rest) . "\n" );

    if ( defined($caps) ) {
        if ( ref($caps) eq 'ARRAY' ) {
            $captures_copy = [ @$caps ];
        } else {
            unshift @rest, $caps;
        }
    }

    unshift @$captures_copy, $site->key;

    # warn( "\nurl: " . Dumper($url) );
    # warn( "\ncaps: " . Dumper($captures_copy) );
    # warn( "\nrest: " . Dumper(\@rest) . "\n" );
    # warn( $c->uri_for( $url, $captures_copy, @rest ) );

    return $c->uri_for( $url, $captures_copy, @rest );
}

sub uri_for_site {
    my ( $c, $url, $caps, @rest ) = @_;

    die("Attempting to create URI for site when site is not defined.") if !defined( $c->site );

    $c->uri_for_given_site( $url, $c->site, $caps, @rest );
}

sub uri_for_static {
    my ( $c, $path ) = @_;

    $path =~ s{^/}{};

    return $c->uri_for( '/static/' . $path );
}




=back

=head1 NAME

CUFTS::Resolver - Catalyst based application

=head1 SYNOPSIS

    script/cufts_resolver_server.pl

=head1 DESCRIPTION

Catalyst based application.

=head1 AUTHOR

Catalyst developer

=head1 LICENSE

This library is free software . You can redistribute it and/or modify
it under the same terms as perl itself.

=cut

1;
