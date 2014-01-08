package CUFTS::Schema::CJDBRelations;

use strict;
use base qw/DBIx::Class::Core/;

__PACKAGE__->load_components(qw//);

__PACKAGE__->table('cjdb_relations');
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
    relation => {
        data_type => 'varchar',
        is_nullable => 0,
        size => 1024,
    },
    title => {
        data_type => 'varchar',
        is_nullable => 0,
        size => 1024,
    },
    issn => {
        data_type => 'varchar',
        is_nullable => 0,
        size => 8,
    },
);

__PACKAGE__->set_primary_key('id');

# Check the ResultSet for more predefined complex searches

__PACKAGE__->belongs_to( journal => 'CUFTS::Schema::CJDBJournals', 'journal' );
__PACKAGE__->belongs_to( site    => 'CUFTS::Schema::Sites',        'site' );

1;
