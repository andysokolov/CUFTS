## CUFTS::Schema::GlobalResources
##
## Copyright Todd Holbrook, Simon Fraser University (2007)
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

package CUFTS::Schema::GlobalResources;

use strict;
use base qw/DBIx::Class::Core/;

use String::Util qw( hascontent );

__PACKAGE__->load_components(qw/ TimeStamp /);

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
        size => 1024,
    },
    module => {
        data_type => 'varchar',
        is_nullable => 0,
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
    notes_for_local => {
        data_type => 'text',
    },
    active => {
        data_type => 'boolean',
        default => 'false',
    },
    title_list_scanned => {
        data_type => 'datetime',
    },
    title_count => {
        data_type => 'integer',
        default => 0,
    },
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

__PACKAGE__->has_many( journals => 'CUFTS::Schema::GlobalJournals',  'resource' );
__PACKAGE__->has_many( local_resources => 'CUFTS::Schema::LocalResources', 'resource' );

1;
