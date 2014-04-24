## CUFTS::Schema::ResourcesList
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


# This is a virtual view that combines local and global resources into one long list for displaying
# in the CUFTS MaintTool under "LocalResources".

package CUFTS::Schema::ResourcesList;

use strict;
use base qw/DBIx::Class::Core/;

use String::Util qw( hascontent trim );

__PACKAGE__->load_components( qw/ InflateColumn::DateTime / );

__PACKAGE__->table_class('DBIx::Class::ResultSource::View');
__PACKAGE__->table('NONE');
__PACKAGE__->result_source_instance->is_virtual(1);

__PACKAGE__->result_source_instance->view_definition(
<<EOF
SELECT resources.id         AS global_id,
       lr.id                AS local_id,
       resources.name       AS name,
       resources.provider   AS provider,
       resource_types.type  AS resource_type,
       lr.active            AS active,
       resources.title_list_scanned AS title_list_scanned,
       lr.rank              AS rank,
       resources.module     AS module,
       lr.auto_activate     AS auto_activate

    FROM resources
    JOIN resource_types ON ( resources.resource_type = resource_types.id )
    LEFT OUTER JOIN ( SELECT * from local_resources WHERE site = ? ) AS lr ON (lr.resource = resources.id)

    UNION

    SELECT NULL as global_id,
           local_resources.id           AS local_id,
           local_resources.name         AS name,
           local_resources.provider     AS provider,
           resource_types.type          AS resource_type,
           local_resources.active       AS active,
           local_resources.title_list_scanned AS title_list_scanned,
           local_resources.rank         AS rank,
           local_resources.module       AS module,
           boolean 'true'               AS auto_activate
    FROM local_resources
    JOIN resource_types ON ( local_resources.resource_type = resource_types.id )
    WHERE site = ? AND resource IS NULL
EOF
);

__PACKAGE__->add_columns(
    global_id => {
      data_type => 'integer',
    },
    local_id => {
      data_type => 'integer',
    },
    name => {
      data_type => 'varchar',
    },
    provider => {
      data_type => 'varchar',
    },
    resource_type => {
      data_type => 'varchar',
    },
    active => {
      data_type => 'boolean',
    },
    title_list_scanned => {
      data_type => 'timestamp',
    },
    rank => {
        data_type => 'integer',
    },
    module => {
        data_type => 'varchar'
    },
    auto_activate => {
        data_type => 'boolean'
    },
);

__PACKAGE__->set_primary_key( 'global_id', 'local_id' );
__PACKAGE__->resultset_class('CUFTS::ResultSet::ResourcesList');


__PACKAGE__->belongs_to( 'local_resource'  => 'CUFTS::Schema::LocalResources',  'local_id' );
__PACKAGE__->belongs_to( 'global_resource' => 'CUFTS::Schema::GlobalResources', 'global_id' );


sub do_module {
    my ($self, $method, @args) = @_;

    my $module = $self->module;
    if ( !hascontent( $module ) ) {
        warn( "Empty module being used, defaulting to blank" );
        $module = 'blank';
    }

    $module = $CUFTS::Config::CUFTS_MODULE_PREFIX . $module;

    return $module->$method(@args);
}

sub is_local  { return !shift->global_id;  }
sub is_global { return !shift->is_local(); }

1;
