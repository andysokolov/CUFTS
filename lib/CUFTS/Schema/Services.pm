package CUFTS::Schema::Services;

use strict;

use base qw/DBIx::Class::Core/;

__PACKAGE__->load_components(qw//);

__PACKAGE__->table('services');
__PACKAGE__->add_columns(
    id => {
      data_type => 'integer',
      is_auto_increment => 1,
      default_value => undef,
      is_nullable => 0,
    },
    name => {
      data_type => 'varchar',
      is_nullable => 0,
      size => '256'
    },
    method => {
      data_type => 'varchar',
      is_nullable => 0,
      size => '256'
    },
    description => {
      data_type => 'text',
      is_nullable => 1,
    },
    created => {
      data_type => 'timestamp',
      default_value => 'NOW()',
      is_nullable => 0,
      size => 0
    },
    modified => {
      data_type => 'timestamp',
      default_value => 'NOW()',
      is_nullable => 0,
      size => 0
    },
);
__PACKAGE__->set_primary_key( 'id' );

1;
