package CUFTS::Schema::ERMContentTypesMain;

use strict;
use base qw/DBIx::Class::Core/;

__PACKAGE__->load_components(qw//);

__PACKAGE__->table('erm_content_types_main');
__PACKAGE__->add_columns(
    id => {
        data_type           => 'integer',
        is_auto_increment   => 1,
        is_nullable         => 0,
        size                => 8,
    },
    erm_main => {
        data_type           => 'integer',
        is_nullable         => 0,
        size                => 8,
    },
    content_type => {
        data_type           => 'integer',
        is_nullable         => 0,
        size                => 8,
    },
);

__PACKAGE__->set_primary_key( 'id' );

__PACKAGE__->belongs_to('erm_main'      => 'CUFTS::Schema::ERMMain');
__PACKAGE__->belongs_to('content_type'  => 'CUFTS::Schema::ERMContentTypes');


1;
