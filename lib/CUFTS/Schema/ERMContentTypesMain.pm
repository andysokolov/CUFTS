package CUFTS::Schema::ERMContentTypesMain;

use strict;
use base qw/DBIx::Class::Core/;

__PACKAGE__->load_components(qw//);

__PACKAGE__->table('erm_content_types_main');
__PACKAGE__->add_columns( qw(
    id
    erm_main
    content_type
));

__PACKAGE__->set_primary_key( 'id' );

__PACKAGE__->belongs_to('erm_main'      => 'CUFTS::Schema::ERMMain');
__PACKAGE__->belongs_to('content_type'  => 'CUFTS::Schema::ERMContentTypes');


1;
