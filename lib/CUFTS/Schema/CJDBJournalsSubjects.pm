package CUFTS::Schema::CJDBJournalsSubjects;

use strict;
use base qw/DBIx::Class::Core/;

__PACKAGE__->load_components(qw//);

__PACKAGE__->table('cjdb_journals_subjects');
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
    subject => {
        data_type => 'integer',
        is_nullable => 0,
    },
    level => {
        data_type => 'integer',
        is_nullable => 0,
        default_value => 0,
    },
    origin => {
        data_type => 'varchar',
        size => 1024,
        is_nullable => 1,
    }
);

__PACKAGE__->set_primary_key('id');

# Check the ResultSet for more predefined complex searches

__PACKAGE__->belongs_to( subject => 'CUFTS::Schema::CJDBSubjects' );
__PACKAGE__->belongs_to( journal => 'CUFTS::Schema::CJDBJournals' );
__PACKAGE__->belongs_to( site    => 'CUFTS::Schema::Sites' );

1;
