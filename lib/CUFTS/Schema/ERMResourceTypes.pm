package CUFTS::Schema::ERMResourceTypes;

use strict;
use base qw/DBIx::Class::Core/;

__PACKAGE__->load_components(qw//);

__PACKAGE__->table('erm_resource_types');
__PACKAGE__->add_columns( qw(
    id
    site
    resource_type
));

__PACKAGE__->set_primary_key( 'id' );

1;

