package CUFTS::CJDB;
use Moose;
use namespace::autoclean;

use String::Util qw(hascontent);

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
    FormValidator
    FillInForm
/;

extends 'Catalyst';

our $VERSION = '0.01';

# Configure the application.
#
# Note that settings in cufts_cjdb.conf (or other external
# configuration file that you set up manually) take precedence
# over this when using ConfigLoader. Thus configuration
# details given here can function as a default configuration,
# with an external configuration file acting as an override for
# local deployment.

__PACKAGE__->config(
    name => 'CUFTS::CJDB',
    # Disable deprecated behavior needed by old applications
    disable_component_resolution_regex_fallback => 1,
);

# Start the application
__PACKAGE__->setup();


sub uri_for_site {
    my ( $c, $url, $caps, @rest ) = @_;

    my $captures_copy = [];

    # use Data::Dumper;
    # warn( "\nurl: " . Dumper($url) );
    # warn( "\ncaps: " . Dumper($caps) );
    # warn( "\nrest: " . Dumper(\@rest) . "\n" );

    die("Attempting to create URI for site when site is not defined.") if !defined( $c->stash->{current_site} );

    if ( defined($caps) ) {
        if ( ref($caps) eq 'ARRAY' ) {
            $captures_copy = [ @$caps ];
        } else {
            unshift @rest, $caps;
        }
    }

    unshift @$captures_copy, $c->stash->{current_site}->key;

    # warn( "\nurl: " . Dumper($url) );
    # warn( "\ncaps: " . Dumper($captures_copy) );
    # warn( "\nrest: " . Dumper(\@rest) . "\n" );
    # warn( $c->uri_for( $url, $captures_copy, @rest ) );

    return $c->uri_for( $url, $captures_copy, @rest );
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
        $c->redirect( $c->uri_for_site( $c->controller('Root')->action_for('indexy') ) );
    }
}



=head1 NAME

CUFTS::CJDB - Catalyst based application

=head1 SYNOPSIS

    script/cufts_cjdb_server.pl

=head1 DESCRIPTION

[enter your description here]

=head1 SEE ALSO

L<CUFTS::CJDB::Controller::Root>, L<Catalyst>

=head1 AUTHOR

tholbroo

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
