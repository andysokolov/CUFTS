package CUFTS::CRDB4::View::JSON;

use strict;
use base 'Catalyst::View::JSON';

use JSON::XS qw();

sub encode_json {
    my ($self, $c, $data) = @_;
    my $encoder = JSON::XS->new->latin1;
    return $encoder->encode($data);
}

=head1 NAME

CUFTS::CRDB4::View::JSON - Catalyst JSON View

=head1 SYNOPSIS

See L<CUFTS::CRDB4>

=head1 DESCRIPTION

Catalyst JSON View.

=head1 AUTHOR

Todd Holbrook

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
