package CUFTS::Schema::LocalResourcesServices;

use strict;

use base qw/DBIx::Class::Core/;

__PACKAGE__->load_components(qw//);

__PACKAGE__->table('local_resources_services');
__PACKAGE__->add_columns(
    id => {
      data_type => 'integer',
      is_auto_increment => 1,
      default_value => undef,
      is_nullable => 0,
    },
    local_resource => {
      data_type => 'integer',
      is_nullable => 0,
    },
    service => {
      data_type => 'integer',
      is_nullable => 0,
    },
    created => {
      data_type => 'timestamp',
      default_value => 'NOW()',
      is_nullable => 0,
      size => 0
    },
);
__PACKAGE__->set_primary_key( 'id' );

__PACKAGE__->belongs_to( local_resource => 'CUFTS::Schema::LocalResources', 'local_resource' );
__PACKAGE__->belongs_to( service        => 'CUFTS::Schema::Services',       'service' );

1;
