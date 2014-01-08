package CUFTS::Schema::JournalsAuthISSNs;

use strict;
use base qw/DBIx::Class::Core/;

__PACKAGE__->load_components(qw//);

__PACKAGE__->table('journals_auth_issns');
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
    issn => {
        data_type => 'varchar',
        is_nullable => 0,
        size => 8,
    },
    info => {
        data_type => 'varchar',
        is_nullable => 1,
        size => 512,
    },

);


__PACKAGE__->set_primary_key('id');

# Check the ResultSet for more predefined complex searches

# __PACKAGE__->resultset_class('CUFTS::ResultSet::JournalsAuthISSNs');

__PACKAGE__->belongs_to( journal_auth => 'CUFTS::Schema::JournalsAuth', 'journal_auth' );


1;