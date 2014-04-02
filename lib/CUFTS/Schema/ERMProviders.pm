package CUFTS::Schema::ERMProviders;

use strict;
use base qw/DBIx::Class::Core/;

__PACKAGE__->load_components(qw//);

__PACKAGE__->table('erm_providers');
__PACKAGE__->add_columns(
    id => {
      data_type => 'integer',
      is_auto_increment => 1,
      default_value => undef,
      is_nullable => 0,
      size => 8,
    },
    key => {
      data_type => 'varchar',
      default_value => undef,
      is_nullable => 1,
      size => 1024,
    },
    site => {
      data_type => 'integer',
      default_value => undef,
      is_nullable => 0,
      size => 10,
    },
    provider_name => {
        data_type => 'varchar',
        default_value => undef,
        is_nullable => 1,
        size => 1024,
    },
    local_provider_name => {
        data_type => 'varchar',
        default_value => undef,
        is_nullable => 1,
        size => 1024,
    },
    admin_user => {
        data_type => 'varchar',
        default_value => undef,
        is_nullable => 1,
        size => 1024,
    },
    admin_password => {
        data_type => 'varchar',
        default_value => undef,
        is_nullable => 1,
        size => 1024,
    },
    admin_url => {
        data_type => 'varchar',
        default_value => undef,
        is_nullable => 1,
        size => 1024,
    },
    support_url => {
        data_type => 'varchar',
        default_value => undef,
        is_nullable => 1,
        size => 1024,
    },
    stats_available => {
        data_type => 'boolean',
        default_value => undef,
        is_nullable => 1,
        size => 0,
    },
    stats_url => {
        data_type => 'varchar',
        default_value => undef,
        is_nullable => 1,
        size => 1024,
    },
    stats_frequency => {
        data_type => 'varchar',
        default_value => undef,
        is_nullable => 1,
        size => 1024,
    },
    stats_delivery => {
        data_type => 'varchar',
        default_value => undef,
        is_nullable => 1,
        size => 1024,
    },
    stats_counter => {
        data_type => 'boolean',
        default_value => undef,
        is_nullable => 1,
        size => 0,
    },
    stats_user => {
        data_type => 'varchar',
        default_value => undef,
        is_nullable => 1,
        size => 1024,
    },
    stats_password => {
        data_type => 'varchar',
        default_value => undef,
        is_nullable => 1,
        size => 1024,
    },
    stats_notes => {
        data_type => 'text',
        default_value => undef,
        is_nullable => 1,
        size => 64000,
    },

    provider_contact => {
        data_type => 'text',
        default_value => undef,
        is_nullable => 1,
        size => 64000,
    },
    provider_notes => {
        data_type => 'text',
        default_value => undef,
        is_nullable => 1,
        size => 64000,
    },

    support_email => {
        data_type => 'varchar',
        default_value => undef,
        is_nullable => 1,
        size => 1024,
    },
    support_phone => {
        data_type => 'varchar',
        default_value => undef,
        is_nullable => 1,
        size => 1024,
    },
    knowledgebase => {
        data_type => 'varchar',
        default_value => undef,
        is_nullable => 1,
        size => 1024,
    },
    customer_number => {
        data_type => 'varchar',
        default_value => undef,
        is_nullable => 1,
        size => 1024,
    },
);

__PACKAGE__->set_primary_key( 'id' );

__PACKAGE__->has_many( 'erm_mains' => 'CUFTS::Schema::ERMMain',  'provider' );

__PACKAGE__->belongs_to( site => 'CUFTS::Schema::Sites' );

1;
