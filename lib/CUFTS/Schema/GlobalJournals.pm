package CUFTS::Schema::GlobalJournals;

use strict;

use String::Util qw(hascontent);
# use CUFTS::Util::Journal;

use base qw/DBIx::Class::Core/;

__PACKAGE__->load_components(qw/ InflateColumn::DateTime TimeStamp /);

__PACKAGE__->table('journals');
__PACKAGE__->add_columns(
    id => {
      data_type => 'integer',
      is_auto_increment => 1,
      is_nullable => 0,
    },
    title => {
      data_type => 'varchar',
      is_nullable => 0,
      size => 1024,
    },
    issn => {
        data_type => 'varchar',
        is_nullable => 1,
        size => 8,
    },
    e_issn => {
        data_type => 'varchar',
        is_nullable => 1,
        size => 8,
    },
    journal_auth => {
        data_type => 'integer',
        is_nullable => 1,
    },
    resource => {
        data_type => 'integer',
        is_nullable => 0,
    },
    vol_cit_start => {
        data_type => 'varchar',
        size => 128,
        is_nullable => 1,
    },
    vol_cit_end => {
        data_type => 'varchar',
        size => 128,
        is_nullable => 1,
    },
    vol_ft_start => {
        data_type => 'varchar',
        size => 128,
        is_nullable => 1,
    },
    vol_ft_end => {
        data_type => 'varchar',
        size => 128,
        is_nullable => 1,
    },
    iss_cit_start => {
        data_type => 'varchar',
        size => 128,
        is_nullable => 1,
    },
    iss_cit_end => {
        data_type => 'varchar',
        size => 128,
        is_nullable => 1,
    },
    iss_ft_start => {
        data_type => 'varchar',
        size => 128,
        is_nullable => 1,
    },
    iss_ft_end => {
        data_type => 'varchar',
        size => 128,
        is_nullable => 1,
    },
    cit_start_date => {
        data_type => 'date',
        is_nullable => 1,
    },
    cit_end_date => {
        data_type => 'date',
        is_nullable => 1,
    },
    ft_start_date => {
        data_type => 'date',
        is_nullable => 1,
    },
    ft_end_date => {
        data_type => 'date',
        is_nullable => 1,
    },
    embargo_months => {
        data_type => 'integer',
        is_nullable => 1,
    },
    embargo_days => {
        data_type => 'integer',
        is_nullable => 1,
    },
    db_identifier => {
        data_type => 'varchar',
        size => 1024,
        is_nullable => 1,
    },
    toc_url => {
        data_type => 'varchar',
        size => 1024,
        is_nullable => 1,
    },
    journal_url => {
        data_type => 'varchar',
        size => 1024,
        is_nullable => 1,
    },
    urlbase => {
        data_type => 'varchar',
        size => 1024,
        is_nullable => 1,
    },
    publisher => {
        data_type => 'varchar',
        size => 1024,
        is_nullable => 1,
    },
    abbreviation => {
        data_type => 'varchar',
        size => 1024,
        is_nullable => 1,
    },
    current_months => {
        data_type => 'integer',
        is_nullable => 1,
    },
    current_years => {
        data_type => 'integer',
        is_nullable => 1,
    },
    coverage => {
        data_type => 'text',
        is_nullable => 1,
    },
    cjdb_note => {
        data_type => 'text',
        is_nullable => 1,
    },
    local_note => {
        data_type => 'text',
        is_nullable => 1,
    },
    scanned => {
        data_type => 'datetime',
        is_nullable => 1,
    },
    created => {
        data_type => 'datetime',
        set_on_create => 1,
        is_nullable => 1,
    },
    modified => {
        data_type => 'datetime',
        set_on_create => 1,
        set_on_update => 1,
        is_nullable => 1,
    },
);

__PACKAGE__->set_primary_key( 'id' );

__PACKAGE__->belongs_to( global_resource => 'CUFTS::Schema::GlobalResources',  'resource' );
__PACKAGE__->belongs_to( journal_auth   => 'CUFTS::Schema::JournalsAuth',    'journal_auth',  { join_type => 'left' } );

# sub store_column {
#     my ( $self, $name, $value ) = @_;

#     return $self->next::method($name, $value) if !hascontent($value);  # Short circuit empty data here and avoid all the validation below.

#     if ( $name eq 'issn' || $name eq 'e_issn' ) {
#         $value = CUFTS::Util::Journal::valid_issn($value)
#             or die("Invalid ISSN: $value");
#     }
#     elsif ( $name eq 'ft_start_date' || $name eq 'cit_start_date' ) {
#         $value = CUFTS::Util::Journal::default_date( $value, 0 );
#     }
#     elsif ( $name eq 'ft_end_date' || $name eq 'cit_end_date' ) {
#         $value = CUFTS::Util::Journal::default_date( $value, 1 );
#     }

#     return $self->next::method($name, $value);
# }

1;
