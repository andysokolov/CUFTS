package CUFTS::Schema::CJDBJournals;

use strict;
use base qw/DBIx::Class::Core/;

__PACKAGE__->load_components(qw/ TimeStamp Helper::ResultSet::SetOperations /);
__PACKAGE__->table('cjdb_journals');
__PACKAGE__->add_columns(
    id => {
      data_type => 'integer',
      is_auto_increment => 1,
      is_nullable => 0,
    },
    journals_auth => {
        data_type => 'integer',
        is_nullable => 0,
    },
    site => {
        data_type => 'integer',
        is_nullable => 0,
    },
    title => {
        data_type => 'varchar',
        is_nullable => 0,
        size => 1024,
    },
    sort_title => {
        data_type => 'varchar',
        is_nullable => 0,
        size => 1024,
    },
    stripped_sort_title => {
        data_type => 'varchar',
        is_nullable => 0,
        size => 1024,
    },
    call_number => {
        data_type => 'varchar',
        is_nullable => 1,
        size => 128,
    },
    image => {
        data_type => 'varchar',
        is_nullable => 1,
        size => 2048,
    },
    image_link => {
        data_type => 'varchar',
        is_nullable => 1,
        size => 2048,
    },
    rss => {
        data_type => 'varchar',
        is_nullable => 1,
        size => 2048,
    },
    miscellaneous => {
        data_type => 'varchar',
        is_nullable => 1,
        size => 2048,
    },
    created => {
        data_type => 'datetime',
        set_on_create => 1,
    },
);

# __PACKAGE__->mk_group_accessors( column => qw/ result_title / );

__PACKAGE__->set_primary_key('id');

# Check the ResultSet for more predefined complex searches

__PACKAGE__->resultset_class('CUFTS::ResultSet::CJDBJournals');

__PACKAGE__->belongs_to( site => 'CUFTS::Schema::Sites' );
__PACKAGE__->belongs_to( journals_auth => 'CUFTS::Schema::JournalsAuth' );

__PACKAGE__->has_many( links     => 'CUFTS::Schema::CJDBLinks',      'journal' );
__PACKAGE__->has_many( issns     => 'CUFTS::Schema::CJDBISSNs',      'journal' );
__PACKAGE__->has_many( relations => 'CUFTS::Schema::CJDBRelations',  'journal' );

__PACKAGE__->has_many( tags => 'CUFTS::Schema::CJDBTags', { 'foreign.journals_auth' => 'self.journals_auth' } );

__PACKAGE__->has_many( journals_titles       => 'CUFTS::Schema::CJDBJournalsTitles',       'journal' );
__PACKAGE__->has_many( journals_subjects     => 'CUFTS::Schema::CJDBJournalsSubjects',     'journal' );
__PACKAGE__->has_many( journals_associations => 'CUFTS::Schema::CJDBJournalsAssociations', 'journal' );

__PACKAGE__->many_to_many( titles       => 'journals_titles',       'title' );
__PACKAGE__->many_to_many( subjects     => 'journals_subjects',     'subject' );
__PACKAGE__->many_to_many( associations => 'journals_associations', 'association' );

sub result_title {
    my $self = shift;
    if ( $self->has_column('result_title') && hascontent($self->has_column('result_title')) ) {
        return $self->get_column('result_title');
    }
    return $self->title;
}

sub display_links {
    my ( $self ) = @_;
    my @results = $self->links->search({},
        {
            '+select' => \'COALESCE(local_journal.cjdb_note, global_journal.cjdb_note)',
            '+as' => 'journal_cjdb_note',
            'join' => { 'local_journal' => 'global_journal' },
        }
    )->all;

    return \@results;
}

1;