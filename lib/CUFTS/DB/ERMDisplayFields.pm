## CUFTS::DB::ERMDisplayFields
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

package CUFTS::DB::ERMDisplayFields;

use strict;
use base 'CUFTS::DB::DBI';

use CUFTS::Util::Simple;

__PACKAGE__->table('erm_display_fields');
__PACKAGE__->columns(Primary => 'id');
__PACKAGE__->columns(All => qw(
    id
    site
    field
    staff_view
    staff_edit
    display_order
));                                                                                                        

__PACKAGE__->columns( Essential => __PACKAGE__->columns );

__PACKAGE__->sequence('erm_display_fields_id_seq');

1;
