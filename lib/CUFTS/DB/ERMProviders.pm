## CUFTS::DB::ERMProviders
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

package CUFTS::DB::ERMProviders;

use strict;
use base 'CUFTS::DB::DBI';


__PACKAGE__->table('erm_providers');
__PACKAGE__->columns(Primary => 'id');
__PACKAGE__->columns(All => qw(
    id
    key
    site

    provider_name
    local_provider_name

    admin_user
    admin_password
    admin_url
    support_url
    
    stats_available
    stats_url
    stats_frequency
    stats_delivery
    stats_counter
    stats_user
    stats_password
    stats_notes

    provider_contact
    provider_notes
    
    support_email
    support_phone
    knowledgebase
    customer_number

));                                        
__PACKAGE__->columns(Essential => __PACKAGE__->columns);

__PACKAGE__->sequence('erm_providers_id_seq');

1;
