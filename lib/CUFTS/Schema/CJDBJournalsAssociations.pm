package CUFTS::Schema::CJDBJournalsAssociations;

use strict;
use base qw/DBIx::Class::Core/;

__PACKAGE__->load_components(qw//);

__PACKAGE__->table('cjdb_journals_associations');
__PACKAGE__->add_columns(
    id => {
      data_type => 'integer',
      is_auto_increment => 1,
      is_nullable => 0,
    },
    site => {
        data_type => 'integer',
        is_nullable => 0,
    },
    journal => {
        data_type => 'integer',
        is_nullable => 0,
    },
    association => {
        data_type => 'integer',
        is_nullable => 0,
    },
);

__PACKAGE__->set_primary_key('id');

# Check the ResultSet for more predefined complex searches

__PACKAGE__->belongs_to( association => 'CUFTS::Schema::CJDBAssociations' );
__PACKAGE__->belongs_to( journal     => 'CUFTS::Schema::CJDBJournals' );
__PACKAGE__->belongs_to( site        => 'CUFTS::Schema::Sites' );

1;
