package CUFTS::Resolver;
use Moose;
use namespace::autoclean;

use lib '../lib';
use CUFTS::Config;

use Catalyst::Runtime 5.80;

# Set flags and add plugins for the application.
#
# Note that ORDERING IS IMPORTANT here as plugins are initialized in order,
# therefore you almost certainly want to keep ConfigLoader at the head of the
# list if you're using it.
#
#         -Debug: activates the debug mode for very useful log messages
#   ConfigLoader: will load the configuration from a Config::General file in the
#                 application's home directory
# Static::Simple: will serve static files from the application's root
#                 directory

use Catalyst qw/
    -Debug
    ConfigLoader
    Static::Simple
    I18N
    Unicode::Encoding
/;
extends 'Catalyst';

has 'site' => (
	is => 'rw',
	isa => 'Object',
);

our $VERSION = '0.01';

# Configure the application.
#
# Note that settings in cufts_resolver.conf (or other external
# configuration file that you set up manually) take precedence
# over this when using ConfigLoader. Thus configuration
# details given here can function as a default configuration,
# with an external configuration file acting as an override for
# local deployment.

__PACKAGE__->config(
    name => 'CUFTS::Resolver',
	encoding => 'UTF-8',
    # Disable deprecated behavior needed by old applications
    disable_component_resolution_regex_fallback => 1,
    enable_catalyst_header => 1, # Send X-Catalyst header
    # Default database connection from Config
    'Model::CUFTS' => {
        connect_info => {
            dsn      => $CUFTS::Config::CUFTS_DB_STRING,
            user     => $CUFTS::Config::CUFTS_USER,
            password => $CUFTS::Config::CUFTS_PASSWORD,
            auto_savepoint => 1
        }
    },
);

# Start the application
__PACKAGE__->setup();


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



=head1 NAME

CUFTS::Resolver - Catalyst based application

=head1 SYNOPSIS

    script/cufts_resolver_server.pl

=head1 DESCRIPTION

[enter your description here]

=head1 SEE ALSO

L<CUFTS::Resolver::Controller::Root>, L<Catalyst>

=head1 AUTHOR

Todd Holbrook

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;