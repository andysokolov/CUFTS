package CUFTS::Schema::Accounts;


use strict;

use base qw/DBIx::Class::Core/;

__PACKAGE__->load_components(qw/ TimeStamp /);

__PACKAGE__->table('accounts');

__PACKAGE__->add_columns(
    id => {
      data_type => 'integer',
      is_auto_increment => 1,
      is_nullable => 0,
    },
    key => {
      data_type => 'varchar',
      is_nullable => 0,
      size => 64,
    },
    name => {
        data_type => 'varchar',
        is_nullable => 0,
        size => 256,
    },
    password => {
        data_type => 'varchar',
        is_nullable => 0,
        size => 32,
    },
    email => {
        data_type => 'varchar',
        is_nullable => 0,
        size => 256,
    },
    phone => {
        data_type => 'varchar',
        is_nullable => 1,
        size => 256,
    },
    administrator => {
        data_type => 'boolean',
        is_nullable => 0,
        default_value => 'false',
    },
    edit_global => {
        data_type => 'boolean',
        is_nullable => 0,
        default_value => 'false',
    },
    journal_auth => {
        data_type => 'boolean',
        is_nullable => 0,
        default_value => 'false',
    },
    active => {
        data_type => 'boolean',
        is_nullable => 0,
        default_value => 'true',
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

# __PACKAGE__->has_many('sites', ['CUFTS::DB::Accounts_Sites' => 'site'], 'account');

1;


