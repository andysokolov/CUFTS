package CUFTS::Schema::CJDBLCCSubjects;

use strict;
use base qw/DBIx::Class::Core/;

__PACKAGE__->load_components(qw//);

__PACKAGE__->table('cjdb_lcc_subjects');
__PACKAGE__->add_columns(
    id => {
      data_type => 'integer',
      is_auto_increment => 1,
      is_nullable => 0,
    },
    site => {
        data_type => 'integer',
        is_nullable => 1,
    },
    class_low => {
        data_type => 'varchar',
        is_nullable => 0,
        size => 3,
    },
    class_high => {
        data_type => 'varchar',
        is_nullable => 0,
        size => 3,
    },
    number_low => {
        data_type => 'numeric',
        is_nullable => 0,
    },
    number_high => {
        data_type => 'numeric',
        is_nullable => 0,
    },
    subject1 => {
        data_type => 'varchar',
        is_nullable => 1,
        size => 2048,
    },
    subject2 => {
        data_type => 'varchar',
        is_nullable => 1,
        size => 2048,
    },
    subject3 => {
        data_type => 'varchar',
        is_nullable => 1,
        size => 2048,
    },
);

__PACKAGE__->set_primary_key('id');

# Check the ResultSet for more predefined complex searches

# __PACKAGE__->resultset_class('CUFTS::ResultSet::CJDBLCCSubjects');

__PACKAGE__->belongs_to( site          => 'CUFTS::Schema::Sites', 'site' );

1;
