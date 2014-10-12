package CUFTS::CRDB4::Controller::Root;
use Moose;
use namespace::autoclean;

use String::Util qw(hascontent);
use JSON::XS qw(encode_json);

BEGIN { extends 'Catalyst::Controller' }

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config(namespace => '');

=encoding utf-8

=head1 NAME

CUFTS::CRDB4::Controller::Root - Root Controller for CUFTS::CRDB4

=head1 DESCRIPTION

[enter your description here]

=head1 METHODS

=head2 index

The root page (/)

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

    # Set up site specific CSS file if it exists
    my $site_css = '/sites/' . $site->id . "/static/css/${box}/crdb.css";
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

    push @{$c->stash->{breadcrumbs}}, [ $c->uri_for_site( $c->controller('Root')->action_for('site_index') ), $c->loc('Electronic Resources') ];
}



sub facet_options : Chained('site') PathPart('') CaptureArgs(0) {

    my ( $self, $c ) = @_;

    my @load_options = (
        [ 'resource_types',   'resource_type',   'CUFTS::ERMResourceTypes' ],
        [ 'resource_mediums', 'resource_medium', 'CUFTS::ERMResourceMediums' ],
        [ 'subjects',         'subject',         'CUFTS::ERMSubjects' ],
        [ 'content_types',    'content_type',    'CUFTS::ERMContentTypes' ],
        [ 'provider',         'provider_name',   'CUFTS::ERMProviders' ],
    );

    foreach my $load_option ( @load_options ) {
        my ( $type, $field, $model ) = @$load_option;

        $c->stash->{$type} = $c->cache->get( $c->site->id . " $type" );
        $c->stash->{"${type}_order"} = $c->cache->get( $c->site->id . " ${type}_order" );

        unless ( $c->stash->{$type} && $c->stash->{"${type}_order"} ) {

            my @records = $c->model($model)->search( { site => $c->site->id }, { order_by => $field } )->all;

            $c->stash->{$type}           = { map { $_->id => $_->$field } @records };
            $c->stash->{"${type}_order"} = [ map { $_->id } @records ];

            $c->cache->set( $c->site->id . " $type" , $c->stash->{$type} );
            $c->cache->set( $c->site->id . " ${type}_order" , $c->stash->{"${type}_order"} );

        }

        $c->stash->{"${type}_json"}    = encode_json( $c->stash->{$type} );
        $c->stash->{"${field}_lookup"} = $c->stash->{$type};  # Alias for looking up when we have the "field" name rather than the type name.
    }

    # Alias provider_name lookup
    $c->stash->{'provider_lookup'} = $c->stash->{'provider_name_lookup'};
}


=head2 index

The root page (/)

=cut


sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->stash->{sites_rs} = $c->model('CUFTS::Sites')->search({ active => 't' }, { order_by => 'name' });
    $c->stash->{template} = 'list_sites.tt';
}

=head2 site_index

The root page for sites (/). Redirects to the browse page right now. Could be a forward to keep the URL cleaner?

=cut


sub site_index :Chained('facet_options') :PathPart('') Args(0) {
    my ( $self, $c ) = @_;

    $c->stash->{template} = 'main.tt';
}


=head2 default

Standard 404 error page

=cut

sub default :Path {
    my ( $self, $c ) = @_;
    $c->response->body( 'Page not found' );
    $c->response->status(404);
}


sub not_allowed :Private {
    my ( $self, $c ) = @_;

    $c->stash->{template} = 'not_allowed.tt';
}

=head2 end

Attempt to render a view, if needed.

=cut

sub end : ActionClass('RenderView') {
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
