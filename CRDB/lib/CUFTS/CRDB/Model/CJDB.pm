package CUFTS::CRDB::Model::CJDB;

use strict;
use base 'Catalyst::Model::DBIC::Schema';

__PACKAGE__->config(
    schema_class => 'CJDB::Schema',
    connect_info => CUFTS::CRDB->config->{connect_info},
);

=head1 NAME

CUFTS::CRDB::Model::Schema - Catalyst DBIC Schema Model
=head1 SYNOPSIS

See L<CUFTS::CRDB>

=head1 DESCRIPTION

L<Catalyst::Model::DBIC::Schema> Model using schema L<CJDB::Schema>

=head1 AUTHOR

Todd Holbrook

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
