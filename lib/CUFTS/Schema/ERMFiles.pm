package CUFTS::Schema::ERMFiles;

use strict;

use base qw/DBIx::Class::Core/;

use CUFTS::Util::Simple;
use Data::UUID;

__PACKAGE__->load_components(qw/ InflateColumn::DateTime /);

__PACKAGE__->table('erm_files');
__PACKAGE__->add_columns( 
    id =>  {
        data_type           => 'integer',
        is_auto_increment   => 1,
        default_value       => undef,
        is_nullable         => 0,
        size                => 8,
    },
    linked_id => {
        data_type           => 'integer',
        is_nullable         => 0,
        size                => 8,
    },
    link_type => {
        data_type          => 'char',
        is_nullable        => 0,
        size               => 1,
    },
    description => {
        data_type          => 'text',
        is_nullable        => 1,
    },
    ext => {
        data_type          => 'varchar',
        is_nullable        => 0,
        size               => 64,
    },
    UUID => {
        data_type          => 'varchar',
        is_nullable        => 0,
        size               => 36,
    },
    created => {
        data_type          => 'timestamp',
        default_value      => 'NOW()',
        is_nullable        => 0,
    },
);                                                                                                        

__PACKAGE__->set_primary_key( 'id' );

sub insert {
    my ( $self, @args ) = @_;
    
    $self->UUID( Data::UUID->new()->create_str() );
    $self->next::method(@args);
    
    return $self;
}

1;
