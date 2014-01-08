package CUFTS::Schema::CJDBAssociations;

use strict;
use base qw/DBIx::Class::Core/;

__PACKAGE__->load_components(qw//);

__PACKAGE__->table('cjdb_associations');
__PACKAGE__->add_columns(
    id => {
      data_type => 'integer',
      is_auto_increment => 1,
      is_nullable => 0,
    },
    association => {
        data_type => 'varchar',
        is_nullable => 0,
        size => 1024,
    },
    search_association => {
        data_type => 'varchar',
        is_nullable => 0,
        size => 1024,
    },
);

__PACKAGE__->set_primary_key('id');

# Check the ResultSet for more predefined complex searches

__PACKAGE__->has_many( journals_associations => 'CUFTS::Schema::CJDBJournalsAssociations', 'association' );

1;
