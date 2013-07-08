package CUFTS::CJDB4;
use Moose;
use namespace::autoclean;

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
    Session
    Session::Store::FastMmap
    Session::State::Cookie
    Cache
    Cache::Store::FastMmap
/;

extends 'Catalyst';

our $VERSION = '4.00';

has 'site' => (
    is => 'rw',
    isa => 'Object',
);

has 'account' => (
    is => 'rw',
    isa => 'Object',
);

# Configure the application.
#
# Note that settings in cufts_cjdb4.conf (or other external
# configuration file that you set up manually) take precedence
# over this when using ConfigLoader. Thus configuration
# details given here can function as a default configuration,
# with an external configuration file acting as an override for
# local deployment.

__PACKAGE__->config(
    name => 'CUFTS::CJDB4',
    # Disable deprecated behavior needed by old applications
    disable_component_resolution_regex_fallback => 1,
    enable_catalyst_header => 1, # Send X-Catalyst header
);

# Start the application
__PACKAGE__->setup();

sub uri_for_site {
    my ( $c, $url, $caps, @rest ) = @_;

    my $captures_copy = [];

    die("Attempting to create URI for site when site is not defined.") if !defined( $c->site );

    if ( defined($caps) ) {
        if ( ref($caps) eq 'ARRAY' ) {
            $captures_copy = [ @$caps ];
        } else {
            unshift @rest, $caps;
        }
    }

    unshift @$captures_copy, $c->site->key;

    return $c->uri_for( $url, $captures_copy, @rest );
}

sub uri_for_static {
    my $c = shift;
    return $c->uri_for( '/static', @_ );
}

sub redirect {
    my ( $c, $uri ) = @_;

    $c->res->redirect( $uri );
    $c->detach();
}

sub redirect_previous {
    my ( $c ) = @_;

    my $uri = $c->session->{prev_uri};

    if ( hascontent($uri) ) {
        $c->redirect($uri);
    }
    else {
        $c->redirect( $c->uri_for_site( $c->controller('Root')->action_for('site_index') ) );
    }
}






=head1 NAME

CUFTS::CJDB4 - Catalyst based application

=head1 SYNOPSIS

    script/cufts_cjdb4_server.pl

=head1 DESCRIPTION

[enter your description here]

=head1 SEE ALSO

L<CUFTS::CJDB4::Controller::Root>, L<Catalyst>

=head1 AUTHOR

Todd Holbrook

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
