## CUFTS::DB::ERMFiles
##
## Copyright Todd Holbrook, Simon Fraser University (2003)
##
## This file is part of CUFTS.
##
## CUFTS is free software; you can redistribute it and/or modify it under
## the terms of the GNU General Public License as published by the Free
## Software Foundation; either version 2 of the License, or (at your option)
## any later version.
## 
## CUFTS is distributed in the hope that it will be useful, but WITHOUT ANY
## WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
## FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
## details.
##
## You should have received a copy of the GNU General Public License along
## with CUFTS; if not, write to the Free Software Foundation, Inc., 59
## Temple Place, Suite 330, Boston, MA 02111-1307 USA

package CUFTS::Schema::ERMFiles;

use strict;
use base qw/DBIx::Class/;

use CUFTS::Util::Simple;
use Data::UUID;

__PACKAGE__->load_components(qw/ InflateColumn::DateTime Core/);

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
