package CUFTS::CRDB;

use lib '../lib';

use strict;
use warnings;

use Catalyst::Runtime '5.70';

use CUFTS::Util::Simple;
use URI::Escape;


# Set flags and add plugins for the application
#
#         -Debug: activates the debug mode for very useful log messages
#   ConfigLoader: will load the configuration from a YAML file in the
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
    Authentication
    Authorization::Roles
    FormValidator
/;

our $VERSION = '0.01';

# Configure the application. 
#
# Note that settings in CUFTS::CRDB.yml (or other external
# configuration file that you set up manually) take precedence
# over this when using ConfigLoader. Thus configuration
# details given here can function as a default configuration,
# with a external configuration file acting as an override for
# local deployment.

__PACKAGE__->config( name => 'CUFTS::CRDB' );

# Start the application
__PACKAGE__->setup;

__PACKAGE__->mk_accessors( qw( site ) );


=head2 session

Override session to provide a site specific block if it is called after we've grabbed the site from the action chain.  Since the
'/site' action generally gets called first, we should be okay using this technique unless we need a site specific session in a begin
or auto block.  Staying with chained actions should prevent this.

This is important for keeping logins to separate CRDB sites from colliding.

=cut

sub session {
    my $c = shift;
    
    my $session = $c->NEXT::session;
    
    if ( $c->site ) {
        my $session_key = 'site_session_' . $c->site->id;
        if ( !defined( $session->{$session_key} ) ) {
            $session->{ $session_key } = {};
        }
        return $session->{ $session_key };
    }

    return $session;  # Session with no site specific partition
}

=head2 uri_for_site

Builds a URI for a site which includes the site key for Chained dispatching

Example call:

    $c->uri_for_site( $c->controller->action_for('resource'), 1243 );

=cut

sub uri_for_site {
    my ( $c, $url, $caps, @rest ) = @_;

    my $captures_copy = [];

    # use Data::Dumper;
    # warn( "\nurl: " . Dumper($url) );
    # warn( "\ncaps: " . Dumper($caps) );
    # warn( "\nrest: " . Dumper(\@rest) . "\n" );

    die("Attempting to create URI for site when site is not defined.") if !defined( $c->site );

    if ( defined($caps) ) {
        if ( ref($caps) eq 'ARRAY' ) {
            $captures_copy = [ @$caps ];
        } else {
            unshift @rest, $caps;
        }
    }

    unshift @$captures_copy, $c->site->key;

    # warn( "\nurl: " . Dumper($url) );
    # warn( "\ncaps: " . Dumper($captures_copy) );
    # warn( "\nrest: " . Dumper(\@rest) . "\n" );
    # warn( $c->uri_for( $url, $captures_copy, @rest ) );

    return $c->uri_for( $url, $captures_copy, @rest );
}

sub uri_for_js {
    my $c = shift;
    return $c->uri_for( '/static/js/', @_ );
}

sub uri_for_css {
    my $c = shift;
    return $c->uri_for( '/static/css/', @_ );
}

sub uri_for_image {
    my $c = shift;
    return $c->uri_for( '/static/images/', @_ );
}

sub uri_for_static {
    my $c = shift;
    return $c->uri_for( '/static', @_ );
}

sub uri_for_facets {
    my ( $c, $add, $remove ) = @_;

    my %new_facets = %{$c->stash->{facets}};
    if ( defined($add) && ref($add) eq 'ARRAY' ) {
        my ( $facet, $value ) = @$add;
        $new_facets{$facet} = $value;
    }
    if ( defined($remove) ) {
        delete $new_facets{$remove};
    }

    my @facet_array = map { uri_escape($_), uri_escape($new_facets{$_}) } sort keys(%new_facets);
    
    return $c->uri_for_site( $c->controller->action_for('html_facets'), @facet_array );
}


sub redirect {
    my ( $c, $uri ) = @_;
    
    $c->res->redirect( $uri );
    $c->detach();
}

sub save_current_action {
    my ( $c ) = @_;

    my $uri      = $c->action;
    my $captures = $c->req->captures;
    my $args     = $c->req->arguments || [];

    my $saved_action = $c->uri_for( $uri, $captures, @$args );
    
    $c->stash->{ return_to } = $saved_action || $c->uri_for_site('/');

    # warn( "Saving action: $saved_action" );
    
    $c->flash->{return_to} = $saved_action || $c->uri_for_site('/');
#    $c->session->{prev_action} = $saved_action;
}



=head1 NAME

CUFTS::CRDB - Catalyst based application

=head1 SYNOPSIS

    script/cufts_crdb_server.pl

=head1 DESCRIPTION

[enter your description here]

=head1 SEE ALSO

L<CUFTS::CRDB::Controller::Root>, L<Catalyst>

=head1 AUTHOR

Todd Holbrook

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
