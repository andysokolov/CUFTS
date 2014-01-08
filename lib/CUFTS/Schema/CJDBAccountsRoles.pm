package CUFTS::Schema::CJDBAccountsRoles;

use strict;
use base qw/DBIx::Class::Core/;

__PACKAGE__->load_components(qw//);

__PACKAGE__->table('cjdb_accounts_roles');

__PACKAGE__->add_columns(
    id => {
      data_type => 'integer',
      is_auto_increment => 1,
      is_nullable => 0,
    },
    account => {
      data_type => 'integer',
      is_nullable => 0,
    },
    role => {
      data_type => 'integer',
      is_nullable => 0,
    },
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->belongs_to( role =>    'CUFTS::Schema::CJDBRoles',    {'foreign.id' => 'self.role'} );
__PACKAGE__->belongs_to( account => 'CUFTS::Schema::CJDBAccounts', {'foreign.id' => 'self.account'} );

1;
