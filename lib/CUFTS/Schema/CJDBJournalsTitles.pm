package CUFTS::Schema::CJDBJournalsTitles;

use strict;
use base qw/DBIx::Class::Core/;

__PACKAGE__->load_components(qw//);

__PACKAGE__->table('cjdb_journals_titles');
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
    title => {
        data_type => 'integer',
        is_nullable => 0,
    },
    main => {
        data_type => 'integer',
        is_nullable => 0,
        size => 1,
        default_value => 0,
    },
);

__PACKAGE__->set_primary_key('id');

# Check the ResultSet for more predefined complex searches

__PACKAGE__->belongs_to( title   => 'CUFTS::Schema::CJDBTitles' );
__PACKAGE__->belongs_to( journal => 'CUFTS::Schema::CJDBJournals' );
__PACKAGE__->belongs_to( site    => 'CUFTS::Schema::Sites' );

1;
