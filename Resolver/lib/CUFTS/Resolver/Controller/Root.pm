package CUFTS::Resolver::Controller::Root;

use strict;
use warnings;
use base 'Catalyst::Controller';

__PACKAGE__->config->{namespace} = '';

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

sub default : Private {
    my ( $self, $c ) = @_;
    $c->redirect('test');
    return;
}

sub base : Chained('/') PathPart('') CaptureArgs(0) {
    my ($self, $c) = @_;

    $c->stash->{extra_js}  = [];
}

sub site : Chained('base') PathPart('site') CaptureArgs(1) {
    my ($self, $c, $site_key) = @_;

    my $site = $c->model('CUFTS::Sites')->find({ key => $site_key });
    if ( !defined($site) ) {
        die("Unrecognized site key: $site_key");
    }
    $c->site( $site );
}

sub end : ActionClass('RenderView') {
    my ( $self, $c ) = @_;

    if ( scalar @{ $c->error } ) {
        $self->_end_error_handling($c);
    }

    return 1 if $c->response->status =~ /^3\d\d$/;
    return 1 if defined($c->response->body);

    unless ( $c->response->content_type ) {
        ### $c->response->content_type('text/html; charset=iso-8859-1');
        $c->response->content_type('text/html; charset=utf-8');
    }

    eval { $c->detach('CUFTS::Resolver::View::TT'); };
    if ( scalar @{ $c->error } ) {
        $self->_end_error_handling($c);
    }

}

sub _end_error_handling {
    my ( $self, $c ) = @_;

    $c->stash(
        template      => 'fatal_error.tt',
        fatal_errors  => $c->error,
    );
    $c->forward('CUFTS::Resolver::View::TT');

    $c->{error} = [];
}


=back

=head1 NAME

CUFTS::Resolver::C::Root - Catalyst component

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
