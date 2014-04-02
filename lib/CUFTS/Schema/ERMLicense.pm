package CUFTS::Schema::ERMLicense;

use strict;
use base qw/DBIx::Class::Core/;

__PACKAGE__->load_components(qw//);

__PACKAGE__->table('erm_license');
__PACKAGE__->add_columns(
    id => {
      data_type => 'integer',
      'is_auto_increment' => 1,
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
    full_on_campus_access => {
      data_type => 'boolean',
      default_value => undef,
      is_nullable => 1,
      size => 0,
    },
    full_on_campus_notes => {
        data_type => 'text',
        default_value => undef,
        is_nullable => 1,
        size => 64000,
    },
    allows_remote_access => {
        data_type => 'boolean',
        default_value => undef,
        is_nullable => 1,
        size => 0,
    },
    allows_proxy_access => {
        data_type => 'boolean',
        default_value => undef,
        is_nullable => 1,
        size => 0,
    },
    allows_commercial_use => {
        data_type => 'boolean',
        default_value => undef,
        is_nullable => 1,
        size => 0,
    },
    allows_walkins => {
        data_type => 'boolean',
        default_value => undef,
        is_nullable => 1,
        size => 0,
    },
    allows_ill => {
        data_type => 'boolean',
        default_value => undef,
        is_nullable => 1,
        size => 0,
    },
    ill_notes => {
        data_type => 'text',
        default_value => undef,
        is_nullable => 1,
        size => 64000,
    },
    allows_ereserves => {
        data_type => 'boolean',
        default_value => undef,
        is_nullable => 1,
        size => 0,
    },
    ereserves_notes => {
        data_type => 'text',
        default_value => undef,
        is_nullable => 1,
        size => 64000,
    },
    allows_coursepacks => {
        data_type => 'boolean',
        default_value => undef,
        is_nullable => 1,
        size => 0,
    },
    coursepack_notes => {
        data_type => 'text',
        default_value => undef,
        is_nullable => 1,
        size => 64000,
    },
    allows_distance_ed => {
        data_type => 'boolean',
        default_value => undef,
        is_nullable => 1,
        size => 0,
    },
    allows_downloads => {
        data_type => 'boolean',
        default_value => undef,
        is_nullable => 1,
        size => 0,
    },
    allows_prints => {
        data_type => 'boolean',
        default_value => undef,
        is_nullable => 1,
        size => 0,
    },
    allows_emails => {
        data_type => 'boolean',
        default_value => undef,
        is_nullable => 1,
        size => 0,
    },
    emails_notes => {
        data_type => 'text',
        default_value => undef,
        is_nullable => 1,
        size => 64000
    },
    allows_archiving => {
        data_type => 'boolean',
        default_value => undef,
        is_nullable => 1,
        size => 0,
    },
    archiving_notes => {
        data_type => 'text',
        default_value => undef,
        is_nullable => 1,
        size => 64000
    },
    own_data => {
        data_type => 'boolean',
        default_value => undef,
        is_nullable => 1,
        size => 0,
    },
    citation_requirements => {
        data_type => 'varchar',
        default_value => undef,
        is_nullable => 1,
        size => 2048,
    },
    requires_print => {
        data_type => 'boolean',
        default_value => undef,
        is_nullable => 1,
        size => 0,
    },
    requires_print_plus => {
        data_type => 'boolean',
        default_value => undef,
        is_nullable => 1,
        size => 0,
    },
    additional_requirements => {
        data_type => 'text',
        default_value => undef,
        is_nullable => 1,
        size => 64000
    },
    allowable_downtime => {
        data_type => 'varchar',
        default_value => undef,
        is_nullable => 1,
        size => 2048,
    },
    online_terms => {
        data_type => 'varchar',
        default_value => undef,
        is_nullable => 1,
        size => 2048,
    },
    user_restrictions => {
        data_type => 'text',
        default_value => undef,
        is_nullable => 1,
        size => 64000
    },
    terms_notes => {
        data_type => 'text',
        default_value => undef,
        is_nullable => 1,
        size => 64000
    },
    termination_requirements => {
        data_type => 'text',
        default_value => undef,
        is_nullable => 1,
        size => 64000
    },
    perpetual_access => {
        data_type => 'boolean',
        default_value => undef,
        is_nullable => 1,
        size => 0,
    },
    perpetual_access_notes => {
        data_type => 'text',
        default_value => undef,
        is_nullable => 1,
        size => 64000
    },
    contact_name => {
        data_type => 'varchar',
        default_value => undef,
        is_nullable => 1,
        size => 2048,
    },
    contact_role => {
        data_type => 'varchar',
        default_value => undef,
        is_nullable => 1,
        size => 2048,
    },
    contact_address => {
        data_type => 'varchar',
        default_value => undef,
        is_nullable => 1,
        size => 2048,
    },
    contact_phone => {
        data_type => 'varchar',
        default_value => undef,
        is_nullable => 1,
        size => 2048,
    },
    contact_fax => {
        data_type => 'varchar',
        default_value => undef,
        is_nullable => 1,
        size => 2048,
    },
    contact_email => {
        data_type => 'varchar',
        default_value => undef,
        is_nullable => 1,
        size => 2048,
    },
    contact_notes => {
        data_type => 'text',
        default_value => undef,
        is_nullable => 1,
        size => 64000
    },
);

__PACKAGE__->set_primary_key( 'id' );

__PACKAGE__->belongs_to( site => 'CUFTS::Schema::Sites' );

__PACKAGE__->has_many( 'erm_mains' => 'CUFTS::Schema::ERMMain',  'license' );


1;
