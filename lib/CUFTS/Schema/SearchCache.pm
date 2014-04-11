package CUFTS::Schema::SearchCache;


use strict;

use base qw/DBIx::Class::Core/;

__PACKAGE__->load_components(qw/ TimeStamp /);

__PACKAGE__->table('searchcache');

__PACKAGE__->add_columns(
    id => {
      data_type => 'integer',
      is_auto_increment => 1,
      is_nullable => 0,
    },
    type => {
      data_type => 'varchar',
      is_nullable => 0,
      size => 1024,
    },
    query => {
        data_type => 'text',
        is_nullable => 0,
    },
    result => {
        data_type => 'text',
        is_nullable => 0,
    },
    created => {
        data_type => 'datetime',
        set_on_create => 1,
    },
);

__PACKAGE__->set_primary_key( 'id' );

1;
