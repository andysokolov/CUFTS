package CUFTS::Schema::CJDBRoles;

use strict;
use base qw/DBIx::Class::Core/;

__PACKAGE__->load_components(qw//);

__PACKAGE__->table('cjdb_roles');
__PACKAGE__->add_columns(
    id => {
      data_type => 'integer',
      is_auto_increment => 1,
      is_nullable => 0,
    },
    role => {
      data_type => 'varchar',
      is_nullable => 0,
      size => 64,
    },
);

__PACKAGE__->set_primary_key('id');

1;