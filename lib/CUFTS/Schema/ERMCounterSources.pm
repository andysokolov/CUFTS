## CUFTS::Schema::ERMCounterSources
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

package CUFTS::Schema::ERMCounterSources;

use strict;
use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/ InflateColumn::DateTime Core/);

__PACKAGE__->table('erm_counter_sources');
__PACKAGE__->add_columns(
    id => {
      data_type => 'integer',
      is_auto_increment => 1,
      default_value => undef,
      is_nullable => 0,
      size => 8,
    },
    site => {
      data_type => 'integer',
      is_nullable => 0,
      size => 8,
    },
    type => {
        data_type => 'char',   # Level of statistics: j - journal, d - database
        size => 1,
        is_nullable => 0,
    },
    name => {
        data_type => 'varchar',
        size => 255,
        is_nullable => 0,
    },
    erm_sushi => {
        data_type => 'integer',
        is_nullable => 0,
        size => 8,
    },
    reference => {
        data_type => 'varchar',
        size => 255,
        is_nullable => 1,
    },
    last_run_timestamp => {
        data_type => 'timestamp',
        is_nullable => 1,
    },
    next_run_date => {
        data_type => 'date',
        is_nullable => 1,
    },
    run_start_date => {
        data_type => 'date',
        is_nullable => 1,
    },
    interval_months => {
        data_type => 'int',
        size => 4,
        is_nullable => 1,
    },
);                                                                                               

__PACKAGE__->set_primary_key( 'id' );

__PACKAGE__->has_many(   'counts'       => 'CUFTS::Schema::ERMCounterCounts', 'counter_source' );
__PACKAGE__->has_many(   'links'        => 'CUFTS::Schema::ERMCounterLinks', 'counter_source' );
__PACKAGE__->belongs_to( 'site'         => 'CUFTS::Schema::Sites', 'site' );
__PACKAGE__->belongs_to( 'erm_sushi'    => 'CUFTS::Schema::ERMSushi', 'erm_sushi' );

1;
