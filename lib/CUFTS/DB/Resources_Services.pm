## CUFTS::DB::Resources_Services
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

package CUFTS::DB::Resources_Services;

use CUFTS::DB::Resources;
use CUFTS::DB::Services;

use strict;
use base 'CUFTS::DB::DBI';

__PACKAGE__->table('resources_services');
__PACKAGE__->columns(Primary => 'id');
__PACKAGE__->columns(All => qw(
	id

	resource
	service
		
	created
	modified
));                                                                                                        

__PACKAGE__->columns(Essential => __PACKAGE__->columns);

__PACKAGE__->sequence('resources_services_id_seq');

__PACKAGE__->has_a('resource' => 'CUFTS::DB::Resources');
__PACKAGE__->has_a('service' => 'CUFTS::DB::Services');



1;

