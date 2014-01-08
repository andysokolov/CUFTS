package CUFTS::Schema::ERMSushi;

use strict;
use base qw/DBIx::Class::Core/;

__PACKAGE__->load_components(qw//);

__PACKAGE__->table('erm_sushi');
__PACKAGE__->add_columns(
    id => {
      data_type => 'integer',
      is_auto_increment => 1,
      default_value => undef,
      is_nullable => 0,
      size => 8,
    },
    site => {
      data_type => 'integer',
      is_nullable => 0,
      size => 8,
    },
    name => {
        data_type => 'varchar',
        size => 255,
        is_nullable => 0,
    },
    requestor => {
        data_type => 'varchar',
        size => 255,
        is_nullable => 1,
    },
    service_url => {
        data_type => 'varchar',
        size => 255,
        is_nullable => 1,
    },
);

__PACKAGE__->set_primary_key( 'id' );

__PACKAGE__->has_many( counter_sources => 'CUFTS::Schema::ERMCounterSources', 'erm_sushi' );

1;
