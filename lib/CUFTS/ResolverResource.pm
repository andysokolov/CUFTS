## CUFTS::ResolverResource
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

package CUFTS::ResolverResource;

use strict;
use base 'Class::Accessor::Fast';

my @columns = qw(
    id
	name

	provider
	resource_type

	module

    proxy
    dedupe
    auto_activate
    rank

	resource_identifier
	database_url
	auth_name
	auth_passwd
	url_base
	proxy_suffix
	
	resource
);

__PACKAGE__->mk_accessors( @columns );                                                                                                        

sub columns {
    return @columns;
}

1;

