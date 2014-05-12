package CUFTS::MaintTool4::View::Tab;

use base qw ( Catalyst::View::Download::CSV );
use strict;
use warnings;

__PACKAGE__->config(
    sep_char    => "\t",
    quote_char  => '',
    stash_key   => 'data',
);

=head1 NAME

CUFTS::MaintTool4::View::Tab - CSV view for CUFTS::MaintTool4

=head1 DESCRIPTION

CSV view for CUFTS::MaintTool4

=head1 SEE ALSO

L<CUFTS::MaintTool4>, L<Catalyst::View::CSV>, L<Text::CSV>

=head1 AUTHOR

Todd Holbrook

=head1 LICENSE

This library is free software . You can redistribute it and/or modify
it under the same terms as perl itself.

=cut

1;
