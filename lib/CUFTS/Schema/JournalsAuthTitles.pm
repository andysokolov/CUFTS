package CUFTS::Schema::JournalsAuthTitles;

use strict;
use base qw/DBIx::Class::Core/;

__PACKAGE__->load_components(qw//);

__PACKAGE__->table('journals_auth_titles');
__PACKAGE__->add_columns(
    id => {
      data_type => 'integer',
      is_auto_increment => 1,
      is_nullable => 0,
    },
    journal_auth => {
      data_type => 'integer',
      is_nullable => 0,
    },
    title => {
        data_type => 'varchar',
        is_nullable => 0,
        size => 1024,
    },
    title_count => {
        data_type => 'integer',
        is_nullable => 0,
        default_value => 0,
    },

);


__PACKAGE__->set_primary_key('id');

# Check the ResultSet for more predefined complex searches

# __PACKAGE__->resultset_class('CUFTS::ResultSet::JournalsAuthTitles');

__PACKAGE__->belongs_to( journal_auth => 'CUFTS::Schema::JournalsAuth', 'journal_auth' );

# This left join is used for orphan cleanup. Ideally this wouldn't be necessary and we'd use DB level constraints
__PACKAGE__->belongs_to( journal_auth_left => 'CUFTS::Schema::JournalsAuth', 'journal_auth', { join_type => 'left' } );

1;