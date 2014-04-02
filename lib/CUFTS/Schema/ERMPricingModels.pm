package CUFTS::Schema::ERMPricingModels;

use strict;
use base qw/DBIx::Class::Core/;

__PACKAGE__->load_components(qw//);

__PACKAGE__->table('erm_pricing_models');
__PACKAGE__->add_columns(
    id => {
        data_type           => 'integer',
        is_auto_increment   => 1,
        is_nullable         => 0,
        size                => 8,
    },
    site => {
        data_type           => 'integer',
        is_nullable         => 0,
        size                => 8,
    },
    pricing_model => {
        data_type     		=> 'varchar',
        is_nullable   		=> 0,
        size          		=> 1024,
    },
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->belongs_to( site => 'CUFTS::Schema::Sites' );

1;

