package CUFTS::Schema::CJDBTags;

use strict;
use base qw/DBIx::Class::Core/;

__PACKAGE__->load_components(qw/ TimeStamp /);

__PACKAGE__->table('cjdb_tags');
__PACKAGE__->add_columns(
    id => {
      data_type => 'integer',
      is_auto_increment => 1,
      is_nullable => 0,
    },
    account => {
      data_type => 'integer',
      is_nullable => 0,
    },
    site => {
      data_type => 'integer',
      is_nullable => 0,
    },
    journals_auth => {
      data_type => 'integer',
      is_nullable => 0,
    },
    tag => {
        data_type => 'varchar',
        is_nullable => 0,
        size => 512,
    },
    level => {
        data_type => 'integer',
        is_nullable => 0,
        default_value => 0,
    },
    viewing => {
        data_type => 'integer',
        is_nullable => 0,
        default_value => 0,
    },
    created => {
        data_type => 'datetime',
        set_on_create => 1,
    },
);

__PACKAGE__->set_primary_key('id');

# Check the ResultSet for more predefined complex searches

__PACKAGE__->belongs_to( journal_auth => 'CUFTS::Schema::JournalsAuth', 'journals_auth' );
__PACKAGE__->belongs_to( account      => 'CUFTS::Schema::CJDBAccounts', 'account' );
__PACKAGE__->belongs_to( site         => 'CUFTS::Schema::Sites',        'site' );

__PACKAGE__->has_many( journals => 'CUFTS::Schema::CJDBJournals', 'journals_auth' );

1;
