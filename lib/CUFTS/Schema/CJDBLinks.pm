package CUFTS::Schema::CJDBLinks;

use strict;
use base qw/DBIx::Class::Core/;

__PACKAGE__->load_components(qw//);

__PACKAGE__->table('cjdb_links');
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
    link_type => {
        data_type => 'integer',
        is_nullable => 0,
    },
    resource => {
        data_type => 'integer',
        is_nullable => 1,
    },
    local_journal => {
        data_type => 'integer',
        is_nullable => 1,
    },
    rank => {
        data_type => 'integer',
        is_nullable => 0,
        default_value => 0,
    },
    print_coverage => {
        data_type => 'varchar',
        is_nullable => 1,
        size => 2048,
    },
    citation_coverage => {
        data_type => 'varchar',
        is_nullable => 1,
        size => 2048,
    },
    fulltext_coverage => {
        data_type => 'varchar',
        is_nullable => 1,
        size => 2048,
    },
    embargo => {
        data_type => 'varchar',
        is_nullable => 1,
        size => 2048,
    },
    current => {
        data_type => 'varchar',
        is_nullable => 1,
        size => 2048,
    },
    url => {
        data_type => 'varchar',
        is_nullable => 1,
        size => 2048,
    },
);

__PACKAGE__->mk_group_accessors( column => qw/ journal_cjdb_note / );
__PACKAGE__->resultset_class('CUFTS::ResultSet::CJDBLinks');

__PACKAGE__->set_primary_key('id');

# Check the ResultSet for more predefined complex searches

# __PACKAGE__->resultset_class('CUFTS::ResultSet::CJDBJournals');

__PACKAGE__->belongs_to( site          => 'CUFTS::Schema::Sites', 'site' );
__PACKAGE__->belongs_to( journal       => 'CUFTS::Schema::CJDBJournals', 'journal' );
__PACKAGE__->belongs_to( local_journal => 'CUFTS::Schema::LocalJournals', 'local_journal', { join_type => 'left' } );

sub local_resource {
    my ($self) = @_;

    my $site_id     = $self->get_column('site');
    my $resource_id = $self->get_column('resource');

    defined($resource_id) or
        return undef;

    my @local_resources = $self->result_source->schema->resultset('LocalResources')->search({ site => $site_id, id => $resource_id })->all;

    if (scalar(@local_resources) == 1) {
        return $local_resources[0];
    } else {
        return undef;
    }
}

# __PACKAGE__->set_sql(display => qq{
#     SELECT cjdb_links.*, COALESCE(local_journals.cjdb_note, journals.cjdb_note) AS journal_cjdb_note FROM cjdb_links
#     LEFT OUTER JOIN local_journals
#     ON cjdb_links.local_journal = local_journals.id
#     LEFT OUTER JOIN journals
#     ON local_journals.journal = journals.id
#     WHERE cjdb_links.journal = ?;
# });


1;
