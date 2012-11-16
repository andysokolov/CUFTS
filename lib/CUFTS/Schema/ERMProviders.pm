## CUFTS::Schema::ERMProviders
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

package CUFTS::Schema::ERMProviders;

use strict;
use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/Core/);

__PACKAGE__->table('erm_providers');
__PACKAGE__->add_columns(
    id => {
      data_type => 'integer',
      is_auto_increment => 1,
      default_value => undef,
      is_nullable => 0,
      size => 8,
    },
    key => {
      data_type => 'varchar',
      default_value => undef,
      is_nullable => 1,
      size => 1024,
    },
    site => {
      data_type => 'integer',
      default_value => undef,
      is_nullable => 0,
      size => 10,
    },
    provider_name => {
        data_type => 'varchar',
        default_value => undef,
        is_nullable => 1,
        size => 1024,
    },
    local_provider_name => {
        data_type => 'varchar',
        default_value => undef,
        is_nullable => 1,
        size => 1024,
    },
    admin_user => {
        data_type => 'varchar',
        default_value => undef,
        is_nullable => 1,
        size => 1024,
    },
    admin_password => {
        data_type => 'varchar',
        default_value => undef,
        is_nullable => 1,
        size => 1024,
    },
    admin_url => {
        data_type => 'varchar',
        default_value => undef,
        is_nullable => 1,
        size => 1024,
    },
    support_url => {
        data_type => 'varchar',
        default_value => undef,
        is_nullable => 1,
        size => 1024,
    },
    local_provider_name => {
        data_type => 'varchar',
        default_value => undef,
        is_nullable => 1,
        size => 1024,
    },
    local_provider_name => {
        data_type => 'varchar',
        default_value => undef,
        is_nullable => 1,
        size => 1024,
    },
    
    stats_available => {
        data_type => 'boolean',
        default_value => undef,
        is_nullable => 1,
        size => 0,
    },
    stats_url => {
        data_type => 'varchar',
        default_value => undef,
        is_nullable => 1,
        size => 1024,
    },
    stats_frequency => {
        data_type => 'varchar',
        default_value => undef,
        is_nullable => 1,
        size => 1024,
    },
    stats_delivery => {
        data_type => 'varchar',
        default_value => undef,
        is_nullable => 1,
        size => 1024,
    },
    stats_counter => {
        data_type => 'boolean',
        default_value => undef,
        is_nullable => 1,
        size => 0,
    },
    stats_user => {
        data_type => 'varchar',
        default_value => undef,
        is_nullable => 1,
        size => 1024,
    },
    stats_password => {
        data_type => 'varchar',
        default_value => undef,
        is_nullable => 1,
        size => 1024,
    },
    stats_notes => {
        data_type => 'text',
        default_value => undef,
        is_nullable => 1,
        size => 64000,
    },
    
    provider_contact => {
        data_type => 'text',
        default_value => undef,
        is_nullable => 1,
        size => 64000,
    },
    provider_notes => {
        data_type => 'text',
        default_value => undef,
        is_nullable => 1,
        size => 64000,
    },
    
    support_email => {
        data_type => 'varchar',
        default_value => undef,
        is_nullable => 1,
        size => 1024,
    },
    support_phone => {
        data_type => 'varchar',
        default_value => undef,
        is_nullable => 1,
        size => 1024,
    },
    knowledgebase => {
        data_type => 'varchar',
        default_value => undef,
        is_nullable => 1,
        size => 1024,
    },
    customer_number => {
        data_type => 'varchar',
        default_value => undef,
        is_nullable => 1,
        size => 1024,
    },
    );                                                                                                        

__PACKAGE__->set_primary_key( 'id' );

__PACKAGE__->has_many( 'erm_mains' => 'CUFTS::Schema::ERMMain',  'provider' );


1;
