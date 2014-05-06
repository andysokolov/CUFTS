package CUFTS::Schema::SiteIPs;

use strict;

use base qw/DBIx::Class::Core/;

__PACKAGE__->load_components(qw/ FromValidatorsCUFTS /);

__PACKAGE__->table('site_ips');
__PACKAGE__->add_columns(
    id => {
      data_type => 'integer',
      is_auto_increment => 1,
      default_value => undef,
      is_nullable => 0,
    },
    site => {
      data_type => 'integer',
      is_nullable => 0,
    },
    ip_low => {
      data_type => 'inet',
      default_value => undef,
      is_nullable => 0,
    },
    ip_high => {
      data_type => 'inet',
      default_value => undef,
      is_nullable => 0,
    },
    created => {
      data_type => 'timestamp',
      default_value => 'NOW()',
      is_nullable => 0,
      size => 0
    },
    modified => {
      data_type => 'timestamp',
      default_value => 'NOW()',
      is_nullable => 0,
      size => 0
    },
);
__PACKAGE__->set_primary_key( 'id' );

__PACKAGE__->belongs_to( site => 'CUFTS::Schema::Sites', 'site' );

1;
