package CUFTS::CRDB::View::TTMobile;

use strict;
use base 'Catalyst::View::TT';

use Scalar::Util qw(blessed);

use Template::Config;
$Template::Config::STASH = 'Template::Stash::XS';

$Template::Stash::SCALAR_OPS->{uri_escape} = sub { my $text = shift; $text =~ s/([^a-zA-Z0-9_.-])/uc sprintf("%%%02x",ord($1))/eg; return $text; };


=head1 NAME

CUFTS::CRDB::View::TTMobile - TT View for CUFTS::CRDB

=head1 DESCRIPTION

TT View for CUFTS::CRDB. 

=head1 AUTHOR

=head1 SEE ALSO

L<CUFTS::CRDB>

Todd Holbrook

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
