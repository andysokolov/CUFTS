package CUFTS::Schema::GlobalResourcesServices;

use strict;
use base qw/DBIx::Class::Core/;

__PACKAGE__->load_components(qw//);

__PACKAGE__->table('resources_services');
__PACKAGE__->add_columns(
    id => {
      data_type => 'integer',
      is_auto_increment => 1,
      default_value => undef,
      is_nullable => 0,
    },
    resource => {
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

__PACKAGE__->belongs_to( resource => 'CUFTS::Schema::GlobalResources', 'resource' );
__PACKAGE__->belongs_to( service  => 'CUFTS::Schema::Services', 'service' );

1;
