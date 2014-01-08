package CUFTS::Schema::Stats;

use strict;

use base qw/DBIx::Class::Core/;

__PACKAGE__->load_components(qw//);

__PACKAGE__->table('stats');

__PACKAGE__->add_columns(
    id => {
        data_type => 'integer',
        is_auto_increment => 1,
        is_nullable => 0,
    },
    site => {
        data_type => 'integer',
        is_nullable => 0,
    },
    request_date => {
        data_type => 'datetime',
        is_nullable => 0,
    },
    request_time => {
        data_type => 'datetime',
        set_on_create => 1,
        is_nullable => 0,
    },
    issn => {
      data_type => 'varchar',
      is_nullable => 1,
      size => 8,
    },
    isbn => {
        data_type => 'varchar',
        is_nullable => 1,
        size => 13,
    },
    title => {
        data_type => 'varchar',
        is_nullable => 1,
        size => 512,
    },
    volume => {
        data_type => 'varchar',
        is_nullable => 1,
        size => 64,
    },
    issue => {
        data_type => 'varchar',
        is_nullable => 1,
        size => 64,
    },
    date => {
        data_type => 'varchar',
        is_nullable => 1,
        size => 64,
    },
    doi => {
        data_type => 'varchar',
        is_nullable => 1,
        size => 128,
    },
    results => {
        data_type => 'boolean',
        is_nullable => 0,
        default_value => 'false',
    },
);

__PACKAGE__->set_primary_key( 'id' );

1;


