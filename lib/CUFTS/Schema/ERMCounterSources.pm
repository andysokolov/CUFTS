package CUFTS::Schema::ERMCounterSources;

use strict;

use base qw/DBIx::Class::Core/;

__PACKAGE__->load_components(qw/ InflateColumn::DateTime /);

__PACKAGE__->table('erm_counter_sources');
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
    type => {
        data_type => 'char',   # Level of statistics: j - journal, d - database
        size => 1,
        is_nullable => 0,
    },
    name => {
        data_type => 'varchar',
        size => 255,
        is_nullable => 0,
    },
    version => {
        data_type => 'varchar',
        size => 16,
        is_nullable => 0,
        default_value => '3',
    },
    email => {
        data_type => 'varchar',
        size => 255,
        is_nullable => 0,
    },
    erm_sushi => {
        data_type => 'integer',
        is_nullable => 0,
        size => 8,
    },
    reference => {
        data_type => 'varchar',
        size => 255,
        is_nullable => 1,
    },
    last_run_timestamp => {
        data_type => 'timestamp',
        is_nullable => 1,
    },
    next_run_date => {
        data_type => 'date',
        is_nullable => 1,
    },
    run_start_date => {
        data_type => 'date',
        is_nullable => 1,
    },
    interval_months => {
        data_type => 'int',
        size => 4,
        is_nullable => 1,
    },
);

__PACKAGE__->set_primary_key( 'id' );

__PACKAGE__->has_many(   'counts'       => 'CUFTS::Schema::ERMCounterCounts', 'counter_source' );
__PACKAGE__->has_many(   'links'        => 'CUFTS::Schema::ERMCounterLinks',  'counter_source' );
__PACKAGE__->belongs_to( 'site'         => 'CUFTS::Schema::Sites', 'site' );
__PACKAGE__->belongs_to( 'erm_sushi'    => 'CUFTS::Schema::ERMSushi', 'erm_sushi' );

1;
