## CUFTS::Resources::SFXDOI
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

package CUFTS::Resources::SFXDOI;

use base qw(CUFTS::Resources::Base::DOI CUFTS::Resources::Base::SFXLoader);

use CUFTS::Exceptions;
use CUFTS::Util::Simple;

use strict;

sub title_list_fields {
    return [
        qw(
            id
            title
            issn
            e_issn
            ft_start_date
            ft_end_date
            vol_ft_start
            vol_ft_end
            iss_ft_start
            iss_ft_end
            journal_url
            cjdb_note
            local_note
            journal_auth
        )
    ];
}


sub can_getTOC {
    return 0;
}

1;
