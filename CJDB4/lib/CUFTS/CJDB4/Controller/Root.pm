package CUFTS::CJDB4::Controller::Root;
use Moose;
use namespace::autoclean;

use String::Util qw(hascontent);

BEGIN { extends 'Catalyst::Controller' }

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config(namespace => '');

=head1 NAME

CUFTS::CJDB4::Controller::Root - Root Controller for CUFTS::CJDB4

=head1 DESCRIPTION

[enter your description here]

=head1 METHODS

=head2 site

Base chain for capturing and loading site from URL

=cut

sub begin : Private {
     my ( $self, $c ) = @_;

    $c->stash->{lang} = $c->req->cookie('pref_lang')->value if ($c->req->cookie('pref_lang'));
    if (my $lang = $c->req->param('set_lang')) {
        $lang =~ s/\W+//isg;
        if (length($lang) == 2) {
            $c->res->cookies->{pref_lang} = { value => $lang };
            $c->stash->{lang} = $lang;
        }
    }
    $c->res->headers->push_header( 'Vary' => 'Accept-Language' );
    $c->languages( $c->stash->{lang} ? [ $c->stash->{lang} ] : undef );

    $c->stash->{languages_list} = $c->installed_languages;
    $c->stash->{selected_lang} = $c->language;

}

sub site :Chained('/') :PathPart('') :CaptureArgs(1) {
    my ($self, $c, $site_key) = @_;
	
    if ( $site_key =~ /^(.+)!sandbox$/ ) {
        $site_key = $1;
        $c->stash->{sandbox} = 1;
    }
    my $box = $c->stash->{sandbox} ? 'sandbox' : 'active';

    my $site = $c->model('CUFTS::Sites')->find({ key => $site_key });
    if ( !defined($site) ) {
        die("Unrecognized site key: $site_key");
    }
    $c->site($site);

    $self->_cache_local_resources($c);

    # Set up site specific CSS file if it exists
    my $site_css = '/sites/' . $site->id . "/static/css/${box}/cjdb.css";
    if ( -e ($c->config->{root} . $site_css) ) {
        $c->stash->{site_css_uri} = $c->uri_for( $site_css );
    }

    $c->stash->{extra_js}    = [];
    $c->stash->{extra_css}   = [];
    $c->stash->{breadcrumbs} = [];

    $c->stash->{additional_template_paths} = [ $c->config->{root} . '/sites/' . $site->id . "/${box}" ];

    # Also setup the account variable

    if ( my $account_id = $c->session->{ $site->id }->{current_account_id} ) {
        my $account = $site->cjdb_accounts->find({ id =>  $account_id });
        $c->account($account);
    }

}


=head2 _cache_local_resources

Build and store information about CUFTS resources such
as whether they are active, display names, any notes, etc.

=cut

sub _cache_local_resources {
    my ( $self, $c ) = @_;

    my $cache_key = 'resources_display_' . $c->site->id;

    if ( !($c->stash->{resources_display} = $c->cache->get($cache_key) ) ) {
        my %resources_display;
        my $local_resources_rs = $c->site->local_resources({ 'me.active' => 't' }, { prefetch => 'resource'} );

        while ( my $local_resource = $local_resources_rs->next ) {

            my $local_resource_id = $local_resource->id;
            my $global_resource   = $local_resource->resource;

            $resources_display{$local_resource_id}->{cjdb_note} = hascontent($local_resource->cjdb_note) ? $local_resource->cjdb_note
                                                                : defined($global_resource)              ? $global_resource->cjdb_note
                                                                :                                          '';

            $resources_display{$local_resource_id}->{name} = hascontent($local_resource->name) ? $local_resource->name
                                                           : defined($global_resource)         ? $global_resource->name
                                                           :                                     '';

            if (!$c->site->cjdb_display_db_name_only) {
                my $provider = hascontent($local_resource->provider) ? $local_resource->provider
                             : defined($global_resource)             ? $global_resource->provider
                             :                                       '';

                $resources_display{$local_resource_id}->{name} .= " - ${provider}";
            }
        }

        $c->stash->{resources_display} = \%resources_display;
        $c->cache->set( $cache_key, \%resources_display );
    }

}


=head2 index

The root page (/). Show a list of sites.

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->stash->{sites_rs} = $c->model('CUFTS::Sites')->search({ active => 't' }, { order_by => 'name' });
    $c->stash->{template} = 'list_sites.tt';
}

=head2 index

The root page for sites (/). Redirects to the browse page right now. Could be a forward to keep the URL cleaner?

=cut


sub site_index :Chained('site') :PathPart('') Args(0) {
    my ( $self, $c ) = @_;

    $c->redirect( $c->uri_for_site( $c->controller('Browse')->action_for('browse') ) );
}


=head2 default



Standard 404 error page

=cut

sub default :Path {
    my ( $self, $c ) = @_;
    $c->response->body( 'Page not found' );
    $c->response->status(404);
}

=head2 end

Attempt to render a view, if needed.

=cut

sub end :ActionClass('RenderView') {
    my ( $self, $c ) = @_;

    $c->response->headers->header( 'Cache-Control' => 'no-cache' );
    $c->response->headers->header( 'Pragma' => 'no-cache' );
    $c->response->headers->expires( time  );

    if ( !$c->response->content_type ) {
        #$c->response->content_type('text/html; charset=iso-8859-1');
        $c->response->content_type('text/html; charset=utf-8');
    }
}

=head1 AUTHOR

Todd Holbrook

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
=======
package CUFTS::CJDB4::Controller::Root;
use Moose;
use namespace::autoclean;

use String::Util qw(hascontent);

BEGIN { extends 'Catalyst::Controller' }

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config(namespace => '');

=head1 NAME

CUFTS::CJDB4::Controller::Root - Root Controller for CUFTS::CJDB4

=head1 DESCRIPTION

[enter your description here]

=head1 METHODS

=head2 site

Base chain for capturing and loading site from URL

=cut

sub site :Chained('/') :PathPart('') :CaptureArgs(1) {
    my ($self, $c, $site_key) = @_;

    if ( $site_key =~ /^(.+)!sandbox$/ ) {
        $site_key = $1;
        $c->stash->{sandbox} = 1;
    }
    my $box = $c->stash->{sandbox} ? 'sandbox' : 'active';

    my $site = $c->model('CUFTS::Sites')->find({ key => $site_key });
    if ( !defined($site) ) {
        die("Unrecognized site key: $site_key");
    }
    $c->site($site);

    $self->_cache_local_resources($c);

    # Set up site specific CSS file if it exists
    my $site_css = '/sites/' . $site->id . "/static/css/${box}/cjdb.css";
    if ( -e ($c->config->{root} . $site_css) ) {
        $c->stash->{site_css_uri} = $c->uri_for( $site_css );
    }

    $c->stash->{extra_js}    = [];
    $c->stash->{extra_css}   = [];
    $c->stash->{breadcrumbs} = [];

    $c->stash->{additional_template_paths} = [ $c->config->{root} . '/sites/' . $site->id . "/${box}" ];

    # Also setup the account variable

    if ( my $account_id = $c->session->{ $site->id }->{current_account_id} ) {
        my $account = $site->cjdb_accounts->find({ id =>  $account_id });
        $c->account($account);
    }

}


=head2 _cache_local_resources

Build and store information about CUFTS resources such
as whether they are active, display names, any notes, etc.

=cut

sub _cache_local_resources {
    my ( $self, $c ) = @_;

    my $cache_key = 'resources_display_' . $c->site->id;

    if ( !($c->stash->{resources_display} = $c->cache->get($cache_key) ) ) {
        my %resources_display;
        my $local_resources_rs = $c->site->local_resources({ 'me.active' => 't' }, { prefetch => 'resource'} );

        while ( my $local_resource = $local_resources_rs->next ) {

            my $local_resource_id = $local_resource->id;
            my $global_resource   = $local_resource->resource;

            $resources_display{$local_resource_id}->{cjdb_note} = hascontent($local_resource->cjdb_note) ? $local_resource->cjdb_note
                                                                : defined($global_resource)              ? $global_resource->cjdb_note
                                                                :                                          '';

            $resources_display{$local_resource_id}->{name} = hascontent($local_resource->name) ? $local_resource->name
                                                           : defined($global_resource)         ? $global_resource->name
                                                           :                                     '';

            if (!$c->site->cjdb_display_db_name_only) {
                my $provider = hascontent($local_resource->provider) ? $local_resource->provider
                             : defined($global_resource)             ? $global_resource->provider
                             :                                       '';

                $resources_display{$local_resource_id}->{name} .= " - ${provider}";
            }
        }

        $c->stash->{resources_display} = \%resources_display;
        $c->cache->set( $cache_key, \%resources_display );
    }

}


=head2 index

The root page (/). Show a list of sites.

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->stash->{sites_rs} = $c->model('CUFTS::Sites')->search({ active => 't' }, { order_by => 'name' });
    $c->stash->{template} = 'list_sites.tt';
}

=head2 index

The root page for sites (/). Redirects to the browse page right now. Could be a forward to keep the URL cleaner?

=cut


sub site_index :Chained('site') :PathPart('') Args(0) {
    my ( $self, $c ) = @_;

    $c->redirect( $c->uri_for_site( $c->controller('Browse')->action_for('browse') ) );
}

sub site_files :Chained('site') :PathPart('sites') :Args() {
    my ( $self, $c, @args ) = @_;

    my $path = $c->config->{root} . '/sites/' . join('/', @args);
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

=head2 end

Attempt to render a view, if needed.

=cut

sub end :ActionClass('RenderView') {
    my ( $self, $c ) = @_;

    $c->response->headers->header( 'Cache-Control' => 'no-cache' );
    $c->response->headers->header( 'Pragma' => 'no-cache' );
    $c->response->headers->expires( time  );

    if ( !$c->response->content_type ) {
        $c->response->content_type('text/html; charset=iso-8859-1');
    }
}

=head1 AUTHOR

Todd Holbrook

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
>>>>>>> .r1808
