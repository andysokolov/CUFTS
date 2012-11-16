package CUFTS::CJDB::Controller::Root;
use Moose;
use namespace::autoclean;

use String::Util qw( trim hascontent );

BEGIN { extends 'Catalyst::Controller' }

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config(namespace => '');

=head1 NAME

CUFTS::CJDB::Controller::Root - Root Controller for CUFTS::CJDB

=head1 DESCRIPTION

[enter your description here]

=head1 METHODS

=head2 site

Base chain for capturing and loading site from URL

=cut

sub site :Chained('/') :PathPart('') :CaptureArgs(1) {
    my ($self, $c, $site_key) = @_;
    
    my $site = CUFTS::DB::Sites->search( key => $site_key )->first;
    if ( !defined($site) ) {
        die("Unrecognized site key: $site_key");
    }
    $c->stash->{current_site} = $site;
    $c->stash->{current_site_key} = $site->key;

    $c->stash->{sandbox} = $c->session->{sandbox};
    my $box = $c->session->{sandbox} ? 'sandbox' : 'active';

    # Set up site specific CSS file if it exists
    my $site_css =   '/sites/' . $site->id . "/static/css/${box}/cjdb.css";
                  
    if ( -e ($c->config->{root} . $site_css) ) {
        $c->stash->{site_css_file} = $c->uri_for( $site_css );
    }

    # Get the current user for the stash if they have logged in
    if ( defined( $c->session->{ $c->stash->{current_site}->id }->{current_account_id} ) ) {
        $c->stash->{current_account} = CJDB::DB::Accounts->retrieve( 
            $c->session->{ $c->stash->{current_site}->id }->{current_account_id} 
        );
    }

    $self->_cache_local_resources($c);
    
    # Store previous action/arguments/parameters data
    if ( $c->req->action !~ /account/ && $c->req->action !~ /ajax/ ) {
        $c->session->{prev_uri} = $c->req->uri;
    }

    $c->stash->{url_base} = $c->request->base . $site->key;
    $c->stash->{additional_template_paths} = [ $c->config->{root} . '/sites/' . $site->id . "/${box}" ];    
    $c->stash->{image_dir} = $c->request->base . '/static/images/';
    $c->stash->{css_dir}   = $c->request->base . '/static/css/';
    $c->stash->{js_dir}    = $c->request->base . '/static/js/';
    $c->stash->{self_url}  = $c->request->base . $c->request->path;
}

sub _cache_local_resources {
    my ( $self, $c ) = @_;

    # Build and store information about CUFTS resources such
    # as whether they are active, display names, any notes, etc.

    my $site_id = $c->stash->{current_site}->id;

    if ( !($c->stash->{resources_display} = $c->cache->get( "resources_display_${site_id}" ) ) ) {
        my %resources_display;
        my $resources_iter = CUFTS::DB::LocalResources->search( { 'site' => $site_id, 'active' => 't' } );

        while (my $resource = $resources_iter->next) {
            my $resource_id = $resource->id;
            my $global_resource = $resource->resource;

            $resources_display{$resource_id}->{cjdb_note} = hascontent($resource->cjdb_note)
                                                            ? $resource->cjdb_note
                                                            : defined($global_resource)
                                                            ? $global_resource->cjdb_note
                                                            : '';
                                                            
            $resources_display{$resource_id}->{name} = hascontent($resource->name) 
                                                       ? $resource->name
                                                       : defined($global_resource)
                                                       ? $global_resource->name 
                                                       : '';
                                                       
            if (!$c->stash->{current_site}->cjdb_display_db_name_only) {
                my $provider = hascontent($resource->provider) 
                               ? $resource->provider
                               : defined($global_resource)
                               ? $global_resource->provider 
                               : '';
                $resources_display{$resource_id}->{name} .= " - ${provider}";
            }
        }
        
        $c->stash->{resources_display} = \%resources_display;
        $c->cache->set( "resources_display_${site_id}", \%resources_display );
    }
    
}


sub indexy :Chained('site') :PathPart('') Args(0) {
    my ( $self, $c ) = @_;

    $c->redirect( $c->uri_for_site( $c->controller('Browse')->action_for('browse') ) );
}

sub set_box :Chained('site') :PathPart('set_box') :Args(1) {
    my ( $self, $c, $box ) = @_;
    
    $c->session->{sandbox} = $box eq 'sandbox' ? 1 : 0;
    
    $c->redirect( $c->uri_for_site( $c->controller->action_for('indexy') ) );
}

sub site_files :Chained('site') :PathPart('sites') :Args(3) {
    my ( $self, $c, @args ) = @_;
    
    my $path = $c->config->{root} . '/sites/' . join('/', @args);
    warn($path);
    $c->serve_static_file($path);
}


=head2 default

Standard 404 error page

=cut

sub default :Path {
    my ( $self, $c ) = @_;
    $c->response->body( 'Page not found' );
    $c->response->status(404);
}

sub favicon : Path('favicon.ico') {
    my ( $self, $c ) = @_;
 
    $c->response->body('');
    $c->response->status(404);
    $c->detach();
}


=head2 end

Attempt to render a view, if needed.

=cut

sub end : Private {
    my ( $self, $c ) = @_;

    if ( scalar @{ $c->error } ) {
        $self->_end_error_handling($c);
    }

    return 1 if $c->response->status =~ /^3\d\d$/;
    return 1 if defined($c->response->body);

    unless ( $c->response->content_type ) {
        $c->response->content_type('text/html; charset=iso-8859-1');
    }

    $c->response->headers->header( 'Cache-Control' => 'no-cache' );
    $c->response->headers->header( 'Pragma' => 'no-cache' );
    $c->response->headers->expires( time  );

    # $c->response->headers->header( 'Cache-Control' => 'private, max-age=5000, pre-check=5000' );
    # $c->response->headers->header( 'Pragma' => 'no-cache' );
    # $c->response->headers->expires( time  );


    # Catch errors in site templates and handle properly.

    eval { $c->forward('CUFTS::CJDB::View::TT'); };
    if ( scalar @{ $c->error } ) {
        $self->_end_error_handling($c);
    }
}

sub _end_error_handling {
    my ( $self, $c ) = @_;

    warn("Rolling back database changes due to error flag.");
    warn( join("\n",  @{ $c->error }) );

    CUFTS::DB::DBI->dbi_rollback();

    $c->stash(
        template      => 'fatal_error.tt',
        fatal_errors  => $c->error,
    );
    $c->forward('CUFTS::CJDB::View::TT');

    $c->{error} = [];
}

=head1 AUTHOR

tholbroo

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
