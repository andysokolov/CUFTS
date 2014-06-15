## CUFTS::Resources::GenericJournalDOI
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

package CUFTS::Resources::GenericJournalDOI;

use base qw(CUFTS::Resources::Base::DOI CUFTS::Resources::Base::Journals);

use CUFTS::Exceptions;
use CUFTS::Util::Simple;

use strict;

sub services {
    return [ qw( fulltext journal database ) ];
}

sub title_list_fields {
    return [
        qw(
            id
            title
            issn
            e_issn
            cit_start_date
            cit_end_date
            ft_start_date
            ft_end_date
            vol_ft_start
            vol_ft_end
            iss_ft_start
            iss_ft_end
            embargo_months
            embargo_days
            coverage
            publisher
            journal_url
            cjdb_note
            local_note
            journal_auth
        )
    ];
}

sub overridable_resource_details {
    return undef;
}

sub title_list_field_map {
    return {
        title          => 'title',
        issn           => 'issn',
        e_issn         => 'e_issn',
        fulltext_start => 'ft_start_date',
        fulltext_end   => 'ft_end_date',
        ft_start_date  => 'ft_start_date',
        ft_end_date    => 'ft_end_date',
        citation_start => 'cit_start_date',
        citation_end   => 'cit_end_date',
        cit_start_date => 'cit_start_date',
        cit_end_date   => 'cit_end_date',
        embargo_months => 'embargo_months',
        embargo_days   => 'embargo_days',
        journal_url    => 'journal_url',
        cjdb_note      => 'cjdb_note',
        vol_ft_start   => 'vol_ft_start',
        vol_ft_end     => 'vol_ft_end',
        iss_ft_start   => 'iss_ft_start',
        iss_ft_end     => 'iss_ft_end',
        vol_cit_start  => 'vol_cit_start',
        vol_cit_end    => 'vol_cit_end',
        iss_cit_start  => 'iss_cit_start',
        iss_cit_end    => 'iss_cit_end',
        publisher      => 'publisher',
    };
}

sub can_getTOC {
    return 0;
}

1;
