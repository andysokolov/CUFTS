package CUFTS::Schema::ERMPricingModels;

use strict;
use base qw/DBIx::Class::Core/;

__PACKAGE__->load_components(qw//);

__PACKAGE__->table('erm_pricing_models');
__PACKAGE__->add_columns( qw(
    id
    site
    pricing_model
));

__PACKAGE__->set_primary_key( 'id' );

1;

