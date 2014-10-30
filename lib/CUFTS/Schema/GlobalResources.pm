package CUFTS::Schema::GlobalResources;

use strict;
use base qw/DBIx::Class::Core/;

use String::Util qw( hascontent );

__PACKAGE__->load_components(qw/ FromValidatorsCUFTS TimeStamp /);

__PACKAGE__->table('resources');
__PACKAGE__->add_columns(
    id => {
        data_type => 'integer',
        is_auto_increment => 1,
        is_nullable => 0,
    },
    key => {
        data_type => 'varchar',
        is_nullable => 0,
        size => 1024,
    },
    name => {
        data_type => 'varchar',
        is_nullable => 0,
        size => 1024,
    },
    resource_type => {
        data_type => 'integer',
        is_nullable => 0,
    },
    provider => {
        data_type => 'varchar',
        is_nullable => 1,
        size => 1024,
    },
    module => {
        data_type => 'varchar',
        is_nullable => 0,
        size => 1024,
    },
    resource_identifier => {
        data_type => 'varchar',
        is_nullable => 1,
        size => 1024,
    },
    database_url => {
        data_type => 'varchar',
        is_nullable => 1,
        size => 1024,
    },
    auth_name => {
        data_type => 'varchar',
        is_nullable => 1,
        size => 1024,
    },
    auth_passwd => {
        data_type => 'varchar',
        is_nullable => 1,
        size => 1024,
    },
    url_base => {
        data_type => 'varchar',
        is_nullable => 1,
        size => 1024,
    },
    proxy_suffix => {
        data_type => 'varchar',
        is_nullable => 1,
        size => 1024,
    },
    cjdb_note => {
        data_type => 'text',
        is_nullable => 1,
    },
    notes_for_local => {
        data_type => 'text',
        is_nullable => 1,
    },
    proquest_identifier => {
        data_type => 'text',
        is_nullable => 1,
    },
    active => {
        data_type => 'boolean',
        is_nullable => 0,
        default_value => 'false',
    },
    title_list_scanned => {
        data_type => 'datetime',
        is_nullable => 1,
    },
    title_list_url => {
        data_type => 'varchar',
        is_nullable => 1,
        size => 1024,
    },
    update_months => {
        data_type => 'integer',
        is_nullable => 1,
    },
    next_update => {
        data_type => 'date',
        is_nullable => 1,
    },
    title_count => {
        data_type => 'integer',
        is_nullable => 0,
        default_value => 0,
    },
    created => {
        data_type => 'datetime',
        set_on_create => 1,
        is_nullable => 0,
    },
    modified => {
        data_type => 'datetime',
        set_on_create => 1,
        set_on_update => 1,
        is_nullable => 0,
    },
);

__PACKAGE__->set_primary_key( 'id' );

__PACKAGE__->belongs_to( resource_type => 'CUFTS::Schema::ResourceTypes',   'resource_type',    { join_type => 'left' } );

__PACKAGE__->has_many( global_journals   => 'CUFTS::Schema::GlobalJournals', 'resource' );
__PACKAGE__->has_many( local_resources   => 'CUFTS::Schema::LocalResources', 'resource' );
__PACKAGE__->has_many( jobs              => 'CUFTS::Schema::JobQueue',       'global_resource_id', { cascade_delete => 0 } );


sub delete_titles {
    my ($self) = @_;

    return $self->do_module('delete_title_list', $self->id, 0);
}


sub record_count {
    my ($self, @other) = @_;

    my $module = $CUFTS::Config::CUFTS_MODULE_PREFIX . $self->module;
    if ($module->has_title_list) {
        my $schema = $self->resultsource->schema;
        return $module->global_rs($schema)->search({ resource => $self->id, @other })->count;
    }

    return undef;
}


sub do_module {
    my ($self, $method, @args) = @_;

    my $module = $self->module;
    if ( !hascontent($module) ) {
        warn( "Empty module being used, defaulting to blank" );
        $module = 'blank';
    }

    $module = $CUFTS::Config::CUFTS_MODULE_PREFIX . $module;
    eval "require $module";
    if ($@) {
        die("Error requiring class = \"$@\"");
    }

    return $module->$method(@args);
}



sub is_local_resource {
    return 0;
}

1;
