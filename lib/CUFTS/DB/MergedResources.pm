## CUFTS::DB::MergedResources
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

# This is for accessing a view with basic detail collated
# for searching.

#
# NOTE: This is a view and cannot be updated at this point
#

package CUFTS::DB::MergedResources;


use CUFTS::Util::Simple;

use strict;
use base 'CUFTS::DB::DBI';

__PACKAGE__->table('merged_resources');
__PACKAGE__->columns(Primary => 'id');
__PACKAGE__->columns(All => qw(
    local_resource
    global_resource
    site
    name
    provider
    resource_type
    module
    proxy
    dedupe
    auto_activate
    erm_main
    rank

    active
));                      

                                                                                  
__PACKAGE__->columns(Essential => __PACKAGE__->columns);

__PACKAGE__->has_a('resource_type' => 'CUFTS::DB::ResourceTypes');
__PACKAGE__->has_a('erm_main' => 'CUFTS::DB::ERMMain');

1;

