package CUFTS::MaintTool::V::JSON;

use strict;
use base 'Catalyst::View::JSON';
use JSON::XS;

__PACKAGE__->config( {
    expose_stash    => 'json',
} );

sub encode_json($) {
    my ($self, $c, $data) = @_;
    my $encoder = JSON::XS->new->latin1;
    $encoder->encode($data);
}


=head1 NAME

CUFTS::MaintTool::V::JSON - Catalyst JSON View

=head1 SYNOPSIS

See L<CUFTS::MaintTool>

=head1 DESCRIPTION

Catalyst JSON View.

=head1 AUTHOR

Todd Holbrook

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
