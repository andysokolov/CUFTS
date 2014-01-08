package CUFTS::Schema::LocalResources;

use strict;
use base qw/DBIx::Class::Core/;

use String::Util qw( hascontent );

__PACKAGE__->load_components(qw/ TimeStamp /);

__PACKAGE__->table('local_resources');
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
    name => {
        data_type => 'varchar',
        is_nullable => 0,
        size => 1024,
    },
    resource_type => {
        data_type => 'integer',
        is_nullable => 1,
    },
    resource => {
        data_type => 'integer',
        is_nullable => 1,
    },
    erm_main => {
        data_type => 'integer',
        is_nullable => 1,
    },
    module => {
        data_type => 'varchar',
        size => 255,
        is_nullable => 1,
    },
    proxy => {
        data_type => 'boolean',
        default => 1,
        is_nullable => 0,
    },
    rank => {
        data_type => 'integer',
        is_nullable => 0,
        default => 0,
    },
    dedupe => {
        data_type => 'boolean',
        default => 0,
        is_nullable => 0,
    },
    auto_activate => {
        data_type => 'boolean',
        default => 1,
        is_nullable => 0,
    },
    provider => {
        data_type => 'varchar',
        size => 1024,
    },
    resource_identifier => {
        data_type => 'varchar',
        size => 1024,
    },
    database_url => {
        data_type => 'varchar',
        size => 1024,
    },
    auth_name => {
        data_type => 'varchar',
        size => 1024,
    },
    auth_passwd => {
        data_type => 'varchar',
        size => 1024,
    },
    url_base => {
        data_type => 'varchar',
        size => 1024,
    },
    proxy_suffix => {
        data_type => 'varchar',
        size => 1024,
    },
    cjdb_note => {
        data_type => 'text',
    },
    active => {
        data_type => 'boolean',
        default => 'false',
    },
    title_list_scanned => {
        data_type => 'datetime',
    },
    # title_count => {
    #     data_type => 'integer',
    #     default => 0,
    # },
    created => {
        data_type => 'datetime',
        set_on_create => 1,
    },
    modified => {
        data_type => 'datetime',
        set_on_create => 1,
        set_on_update => 1,
    },
);

__PACKAGE__->set_primary_key( 'id' );

__PACKAGE__->belongs_to( resource => 'CUFTS::Schema::GlobalResources', 'resource', { join_type => 'left' } );
__PACKAGE__->belongs_to( erm_main => 'CUFTS::Schema::ERMMain',         'erm_main', { join_type => 'left' } );

__PACKAGE__->has_many( local_journals    => 'CUFTS::Schema::LocalJournals',          'resource' );
__PACKAGE__->has_many( resource_services => 'CUFTS::Schema::LocalResourcesServices', 'local_resource' );

__PACKAGE__->many_to_many( services => 'resource_services', 'service' );

sub name_display {
    my $self = shift;

    return   hascontent($self->name)  ? $self->name
           : defined($self->resource) ? $self->resource->name
                                      : '';
}

sub provider_display {
    my $self = shift;

    return   hascontent($self->provider) ? $self->provider
           : defined($self->resource)    ? $self->resource->provider
                                         : '';
}


1;
