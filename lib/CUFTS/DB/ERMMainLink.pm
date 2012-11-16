## CUFTS::DB::ERMMainLink
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

package CUFTS::DB::ERMMainLink;

use strict;
use base 'CUFTS::DB::DBI';

# link_type
# r - local_resource
# j - local_journal

__PACKAGE__->table('erm_main_link');
__PACKAGE__->columns(Primary => 'id');
__PACKAGE__->columns(All => qw(
    id
    erm_main
    link_type
    link_id
));

__PACKAGE__->columns( TEMP => qw( _linked_name ) );
                                                                      
__PACKAGE__->columns(Essential => __PACKAGE__->columns);

__PACKAGE__->sequence('erm_main_link_id_seq');

sub linked_name {
    my ( $self ) = @_;
    
    if ( !defined($self->_linked_name) ) {

        if ( $self->link_type eq 'r' ) {

            my $local_resource = CUFTS::DB::LocalResources->retrieve( $self->link_id );
            return '' if !defined($local_resource);   # Orphan link, these should be cleaned up
            
            if ( $local_resource->name ) {
                $self->_linked_name( $local_resource->name );
            }
            else {
                return '' if !defined($local_resource->resource);   # Orphan link, these should be cleaned up
                $self->_linked_name( $local_resource->resource->name );
            }

        }
        elsif ( $self->link_type eq 'j' ) {

            my $local_journal = CUFTS::DB::LocalJournals->retrieve( $self->link_id );
            return '' if !defined($local_journal);    # Orphan link, these should be cleaned up
            
            if ( $local_journal->title ) {
                $self->_linked_name( $local_journal->title );
            }
            else {
                return '' if !defined($local_journal->journal);   # Orphan link, these should be cleaned up
                $self->_linked_name( $local_journal->journal->title );
            }

        }
        else {

            warn("Unrecognized link_type in ERMMainLink->linked_name(): " . $self->link_type);
            return '';

        }
    
    }

    return $self->_linked_name;
}

1;
