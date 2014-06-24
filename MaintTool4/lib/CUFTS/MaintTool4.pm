package CUFTS::MaintTool4;
use Moose;
use namespace::autoclean;

use CUFTS::JQ::Client;
use String::Util qw( trim hascontent );

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
    Session::Store::File
    Session::State::Cookie
    Authentication
    FormValidator
    I18N
/;

extends 'Catalyst';

our $VERSION = '0.01';

# Configure the application.
#
# Note that settings in cufts_mainttool.conf (or other external
# configuration file that you set up manually) take precedence
# over this when using ConfigLoader. Thus configuration
# details given here can function as a default configuration,
# with an external configuration file acting as an override for
# local deployment.

__PACKAGE__->config(
    name => 'CUFTS::MaintTool4',
    # Disable deprecated behavior needed by old applications
    disable_component_resolution_regex_fallback => 1,
);

# Start the application
__PACKAGE__->setup();

has 'site' => (
    is => 'rw',
    isa => 'Object',
);

sub stash_errors {
    push @{shift->stash->{errors}}, @_;
}

sub stash_results {
    push @{shift->stash->{results}}, @_;
}

sub flash_errors {
    push @{shift->flash->{errors}}, @_;
}

sub flash_results {
    push @{shift->flash->{results}}, @_;
}

sub form_has_errors {
    my ( $c ) = @_;
    return $c->form->has_missing || $c->form->has_invalid || $c->form->has_unknown;
}

sub stash_params {
    my $c = shift;
    $c->stash->{params} = $c->request->params;
}

sub has_param {
    my ( $c, $param ) = @_;
    return hascontent( $c->request->params->{$param} );
}

sub job_queue {
    my ( $c ) = @_;
    my $log_fh = IO::File->new(">> $CUFTS::Config::CUFTS_JQ_LOG");
    warn("Unable to open JQ log file: $!") if !defined $log_fh;
    my $jq_data = {
        job_schema  => $c->model('CUFTS')->schema,
        work_schema => $c->model('CUFTS')->schema,
        identifier  => 'MaintTool4',
        account_id  => $c->user->id,
        log_fh      => $log_fh,
    };
    $jq_data->{site_id} = $c->site->id if defined $c->site;

    return CUFTS::JQ::Client->new($jq_data);
}

sub redirect {
    my ( $c, $uri ) = @_;

    $c->res->redirect( $uri );
    $c->detach();
}

sub uri_for_static {
    my ( $c, $path ) = @_;
    $path =~ s{^/}{};
    return $c->uri_for( '/static/' . $path );
}


=head1 NAME

CUFTS::MaintTool4 - Catalyst based application

=head1 SYNOPSIS

    script/cufts_mainttool_server.pl

=head1 DESCRIPTION

[enter your description here]

=head1 SEE ALSO

L<CUFTS::MaintTool4::Controller::Root>, L<Catalyst>

=head1 AUTHOR

tholbroo

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
