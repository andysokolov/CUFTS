package CUFTS::Schema::ERMConsortia;

use strict;
use base qw/DBIx::Class::Core/;

__PACKAGE__->load_components(qw//);

__PACKAGE__->table('erm_consortia');
__PACKAGE__->add_columns( qw(
    id
    site
    consortia
));

__PACKAGE__->set_primary_key( 'id' );

1;

