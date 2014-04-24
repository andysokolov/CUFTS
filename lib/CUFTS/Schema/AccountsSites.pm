package CUFTS::Schema::AccountsSites;

use strict;

use base qw/DBIx::Class::Core/;

__PACKAGE__->load_components(qw/ TimeStamp /);

__PACKAGE__->table('accounts_sites');

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
    site => {
      data_type => 'integer',
      is_nullable => 0,
    },
    created => {
        data_type => 'datetime',
        set_on_create => 1,
    },
    modified => {
        data_type => 'datetime',
        set_on_create => 1,
        set_on_update => 1,
    },
);

__PACKAGE__->set_primary_key( 'id' );

__PACKAGE__->belongs_to( 'site' => 'CUFTS::Schema::Sites', 'site' );
__PACKAGE__->belongs_to( 'account' => 'CUFTS::Schema::Accounts', 'account' );

1;
