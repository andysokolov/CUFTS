package CUFTS::Schema::ERMCounterLinks;

use strict;
use base qw/DBIx::Class::Core/;

use Date::Calc qw(Days_in_Month);

__PACKAGE__->load_components(qw//);

__PACKAGE__->table('erm_counter_links');
__PACKAGE__->add_columns(
    id => {
      data_type => 'integer',
      is_auto_increment => 1,
      default_value => undef,
      is_nullable => 0,
      size => 8,
    },
    identifier => {
        data_type => 'text',
        is_nullable => 1,
    },
    counter_source => {
        data_type => 'integer',
        is_nullable => 0,
        size => 8,
    },
    erm_main => {
        data_type => 'integer',
        is_nullable => 0,
        size => 8,
    },
);

__PACKAGE__->set_primary_key( 'id' );

__PACKAGE__->belongs_to( 'counter_source' => 'CUFTS::Schema::ERMCounterSources' );




1;
