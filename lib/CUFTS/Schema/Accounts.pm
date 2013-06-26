## CUFTS::Schema::Accounts
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

package CUFTS::Schema::Accounts;


use strict;

use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/ TimeStamp Core /);

__PACKAGE__->table('accounts');

__PACKAGE__->add_columns(
    id => {
      data_type => 'integer',
      is_auto_increment => 1,
      is_nullable => 0,
    },
    key => {
      data_type => 'varchar',
      is_nullable => 0,
      size => 64,
    },
    name => {
        data_type => 'varchar',
        is_nullable => 0,
        size => 256,
    },
    password => {
        data_type => 'varchar',
        is_nullable => 0,
        size => 32,
    },
    email => {
        data_type => 'varchar',
        is_nullable => 0,
        size => 256,
    },
    phone => {
        data_type => 'varchar',
        is_nullable => 1,
        size => 256,
    },
    administrator => {
        data_type => 'boolean',
        is_nullable => 0,
        default_value => 'false',
    },
    edit_global => {
        data_type => 'boolean',
        is_nullable => 0,
        default_value => 'false',
    },
    journal_auth => {
        data_type => 'boolean',
        is_nullable => 0,
        default_value => 'false',
    },
    active => {
        data_type => 'boolean',
        is_nullable => 0,
        default_value => 'true',
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

# __PACKAGE__->has_many('sites', ['CUFTS::DB::Accounts_Sites' => 'site'], 'account');

1;


