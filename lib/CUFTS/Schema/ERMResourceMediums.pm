package CUFTS::Schema::ERMResourceMediums;

use strict;
use base qw/DBIx::Class::Core/;

__PACKAGE__->load_components(qw//);

__PACKAGE__->table('erm_resource_mediums');
__PACKAGE__->add_columns( qw(
    id
    site
    resource_medium
));                                                                                                        

__PACKAGE__->set_primary_key( 'id' );

1;
