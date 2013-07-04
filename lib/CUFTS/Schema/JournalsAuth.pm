package CUFTS::Schema::JournalsAuth;

use strict;
use base qw/DBIx::Class::Core/;

__PACKAGE__->load_components(qw/ TimeStamp /);
__PACKAGE__->table('journals_auth');
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
    marc => {
        data_type => 'text',
        is_nullable => 1,
    },
    rss => {
        data_type => 'varchar',
        is_nullable => 1,
        size => 2048,
    },
    active => {
        data_type => 'boolean',
        is_nullable => 0,
        default_value => 't',
    },
    created => {
        data_type => 'datetime',
        set_on_create => 1,
    },
    modified => {
        data_type => 'datetime',
        set_on_update => 1,
        set_on_create => 1,
    },
);


__PACKAGE__->set_primary_key('id');

# Check the ResultSet for more predefined complex searches

# __PACKAGE__->resultset_class('CUFTS::ResultSet::JournalsAuth');

__PACKAGE__->has_many( issns   => 'CUFTS::Schema::JournalsAuthISSNs', 'journal_auth' );
# __PACKAGE__->has_many( titles  => 'CUFTS::Schema::JournalsAuthTitles', 'journal_auth' );

sub issns_display {
    my $self = shift;

    my @issns = map { substr($_->issn,0,4) . '-' . substr($_->issn,4,4) } $self->issns;

    return \@issns;
}


1;