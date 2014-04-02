package CUFTS::Schema::ERMUses;

use strict;
use base qw/DBIx::Class::Core/;

__PACKAGE__->load_components(qw//);

__PACKAGE__->table('erm_uses');
__PACKAGE__->add_columns(
    id => {
      data_type => 'integer',
      is_auto_increment => 1,
      default_value => undef,
      is_nullable => 0,
      size => 8,
    },
    erm_main => {
      data_type => 'integer',
      is_nullable => 0,
      size => 8,
    },
    date => {
        data_type => 'datetime',
        is_nullable => 0,
        default_value => \'NOW()',
    },
);

__PACKAGE__->set_primary_key( 'id' );

__PACKAGE__->belongs_to( erm_main => 'CUFTS::Schema::ERMMain' );


1;
