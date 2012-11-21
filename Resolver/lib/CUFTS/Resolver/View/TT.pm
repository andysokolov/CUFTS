package CUFTS::Resolver::View::TT;

use strict;
use base 'Catalyst::View::TT';

__PACKAGE__->config( {
    ENCODING     => 'utf-8',
} );

use Template::Filters;    # Need to use, so that we can have access to $Template::Filters::FILTERS
$Template::Filters::FILTERS->{escape_js_string} = \&escape_js_string;

sub escape_js_string {
    my $s = shift;
    $s =~ s/(\\|'|"|\/)/\\$1/g;
    return $s;
}

=head1 NAME

CUFTS::Resolver::V::TT - TT View Component

=head1 SYNOPSIS

See L<CUFTS::Resolver>

=head1 DESCRIPTION

TT View Component.

=head1 AUTHOR

A clever guy

=head1 LICENSE

This library is free software . You can redistribute it and/or modify
it under the same terms as perl itself.

=cut

1;
