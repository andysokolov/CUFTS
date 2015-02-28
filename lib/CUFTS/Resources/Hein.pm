## CUFTS::Resources::Hein
##
## Copyright Todd Holbrook - Simon Fraser University (2003)
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

package CUFTS::Resources::Hein;

use base qw(CUFTS::Resources::KBARTJournal);
use String::Util qw(hascontent);

use strict;

sub clean_data {
    my ( $class, $record ) = @_;

    my $errs = $class->SUPER::clean_data($record);

    if ( $record->{___publication_type} eq 'monograph' ) {
        $record->{ft_start_date} = $record->{___date_monograph_published_print};
        $record->{ft_end_date}   = $record->{___date_monograph_published_print};
        $class->SUPER::clean_data_dates($record); # Re-run this to get YYYY to YYYY-MM-DD
    }

    if ( hascontent($record->{ft_end_date}) ) {
    	delete $record->{embargo_days};
    	delete $record->{embargo_months};
    }

    return $errs;
}


1;
