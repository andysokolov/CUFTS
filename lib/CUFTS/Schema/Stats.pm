## CUFTS::Schema::Stats
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

package CUFTS::Schema::Stats;


use strict;

use base qw/DBIx::Class::Core/;

__PACKAGE__->load_components(qw//);

__PACKAGE__->table('stats');

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
    request_date => {
        data_type => 'datetime',
        is_nullable => 0,
    },
    request_time => {
        data_type => 'datetime',
        set_on_create => 1,
        is_nullable => 0,
    },
    issn => {
      data_type => 'varchar',
      is_nullable => 1,
      size => 8,
    },
    isbn => {
        data_type => 'varchar',
        is_nullable => 1,
        size => 13,
    },
    title => {
        data_type => 'varchar',
        is_nullable => 1,
        size => 512,
    },
    volume => {
        data_type => 'varchar',
        is_nullable => 1,
        size => 64,
    },
    issue => {
        data_type => 'varchar',
        is_nullable => 1,
        size => 64,
    },
    date => {
        data_type => 'varchar',
        is_nullable => 1,
        size => 64,
    },
    doi => {
        data_type => 'varchar',
        is_nullable => 1,
        size => 128,
    },
    results => {
        data_type => 'boolean',
        is_nullable => 0,
        default_value => 'false',
    },
);

__PACKAGE__->set_primary_key( 'id' );

1;


