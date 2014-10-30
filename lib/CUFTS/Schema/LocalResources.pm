package CUFTS::Schema::LocalResources;

use strict;

use String::Util qw( hascontent );

use Moose;

extends qw/DBIx::Class::Core/;

__PACKAGE__->load_components(qw/ FromValidatorsCUFTS TimeStamp /);

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
        is_nullable => 1,
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
        default_value => 1,
        is_nullable => 0,
    },
    rank => {
        data_type => 'integer',
        is_nullable => 0,
        default_value => 0,
    },
    dedupe => {
        data_type => 'boolean',
        default_value => 'false',
        is_nullable => 0,
    },
    auto_activate => {
        data_type => 'boolean',
        default_value => 'true',
        is_nullable => 0,
    },
    provider => {
        data_type => 'varchar',
        size => 1024,
        is_nullable => 1,
    },
    resource_identifier => {
        data_type => 'varchar',
        size => 1024,
        is_nullable => 1,
    },
    database_url => {
        data_type => 'varchar',
        size => 1024,
        is_nullable => 1,
    },
    auth_name => {
        data_type => 'varchar',
        size => 1024,
        is_nullable => 1,
    },
    auth_passwd => {
        data_type => 'varchar',
        size => 1024,
        is_nullable => 1,
    },
    url_base => {
        data_type => 'varchar',
        size => 1024,
        is_nullable => 1,
    },
    proxy_suffix => {
        data_type => 'varchar',
        size => 1024,
        is_nullable => 1,
    },
    cjdb_note => {
        data_type => 'text',
        is_nullable => 1,
    },
    proquest_identifier => {
        data_type => 'text',
        is_nullable => 1,
    },
    active => {
        data_type => 'boolean',
        default_value => 'true',
        is_nullable => 0,
    },
    title_list_scanned => {
        data_type => 'datetime',
        is_nullable => 1,
    },
    # title_count => {
    #     data_type => 'integer',
    #     default_value => 0,
    # },
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

__PACKAGE__->belongs_to( site          => 'CUFTS::Schema::Sites', 'site' );

__PACKAGE__->belongs_to( resource      => 'CUFTS::Schema::GlobalResources', 'resource',         { join_type => 'left' } );
__PACKAGE__->belongs_to( erm_main      => 'CUFTS::Schema::ERMMain',         'erm_main',         { join_type => 'left' } );
__PACKAGE__->belongs_to( resource_type => 'CUFTS::Schema::ResourceTypes',   'resource_type',    { join_type => 'left' } );

__PACKAGE__->has_many( local_journals    => 'CUFTS::Schema::LocalJournals', 'resource' );
__PACKAGE__->has_many( jobs              => 'CUFTS::Schema::JobQueue',      'local_resource_id', { cascade_delete => 0 } );

before 'delete' => sub {
    shift->delete_titles();
};

sub global_resource {
    shift->resource(@_);
}

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


sub delete_titles {
    my ($self) = @_;

    return $self->do_module('delete_title_list', $self->result_source->schema, $self->id, 1);
}


sub record_count {
    my ($self, @other) = @_;

    my $module = $CUFTS::Config::CUFTS_MODULE_PREFIX . ( $self->module || $self->global_resource->module);
    if ($module->has_title_list) {
        my $schema = $self->result_source->schema;
        return $module->local_rs($schema)->search({ resource => $self->id, @other })->count;
    }

    return undef;
}


sub do_module {
    my ($self, $method, @args) = @_;

    my $module = $self->module;
    if ( !hascontent($module) ) {
        if ( defined $self->global_resource  && hascontent($self->global_resource->module) ) {
            $module = $self->global_resource->module;
        }
        else {
            warn( "Empty module being used, defaulting to blank" );
            $module = 'blank';
        }
    }

    $module = $CUFTS::Config::CUFTS_MODULE_PREFIX . $module;

    eval "require $module";
    if ($@) {
        die("Error requiring class = \"$@\"");
    }

    return $module->$method(@args);
}



sub is_local_resource {
    return 1;
}



no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);

1;
