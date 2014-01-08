package CUFTS::Schema::ERMCosts;

use strict;
use base qw/DBIx::Class::Core/;

__PACKAGE__->load_components(qw//);

__PACKAGE__->table('erm_costs');
__PACKAGE__->add_columns(
    id => {
      data_type => 'integer',
      is_auto_increment => 1,
      default_value => undef,
      is_nullable => 0,
      size => 8,
    },
    erm_main => {
      data_type => 'integer',
      is_nullable => 0,
      size => 8,
    },
    number => {
        data_type => 'varchar',
        size => 256,
        is_nullable => 1,
    },
    order_number => {
        data_type => 'varchar',
        size => 256,
        is_nullable => 1,
    },
    reference => {
        data_type => 'varchar',
        size => 256,
        is_nullable => 1,
    },
    date => {
        data_type => 'date',
        is_nullable => 0,
    },
    invoice => {
        data_type => 'number',
        is_nullable => 1,
    },
    invoice_currency => {
        data_type => 'varchar',
        is_nullable => 1,
        size => 3,
    },
    paid => {
        data_type => 'number',
        is_nullable => 1,
    },
    paid_currency => {
        data_type => 'varchar',
        is_nullable => 1,
        size => 3,
    },
    period_start => {
        data_type => 'date',
        is_nullable => 1,
    },
    period_end => {
        data_type => 'date',
        is_nullable => 1,
    },
);

__PACKAGE__->set_primary_key( 'id' );

__PACKAGE__->belongs_to( 'erm_main' => 'CUFTS::Schema::ERMMain' );


1;
