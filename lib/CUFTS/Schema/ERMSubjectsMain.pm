## CUFTS::DB::ERMSubjectsMain
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

package CUFTS::Schema::ERMSubjectsMain;

use strict;
use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto Core/);

__PACKAGE__->table('erm_subjects_main');
__PACKAGE__->add_columns( qw(
    id
    erm_main
    subject
    rank
    description
));                                                                                                        

__PACKAGE__->set_primary_key( 'id' );

__PACKAGE__->belongs_to( 'erm_main' => 'CUFTS::Schema::ERMMain' );
__PACKAGE__->belongs_to( 'subject'  => 'CUFTS::Schema::ERMSubjects' );


1;
