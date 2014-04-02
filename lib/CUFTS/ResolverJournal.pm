## CUFTS::ResolverJournal
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

package CUFTS::ResolverJournal;

use strict;
use Moose;

my @columns = qw(
    title
    issn
    e_issn
    vol_cit_start
    vol_cit_end
    iss_cit_start
    iss_cit_end
    vol_ft_start
    vol_ft_end
    iss_ft_start
    iss_ft_end
    cit_start_date
    cit_end_date
    ft_start_date
    ft_end_date
    embargo_months
    embargo_days
    urlbase
    db_identifier
    journal_url
    toc_url
    publisher
    abbreviation
    current_years
    current_months
    coverage
);

sub columns {
    return @columns;
}

foreach my $col (@columns) {
    has $col => (
        isa => 'Maybe[Str|Object]',
        is  => 'rw',
    );
}

has 'id' => (
    isa => 'Int',
    is  => 'rw',
);

has 'journal_auth' => (
    isa => 'Maybe[Object]',
    is  => 'rw',
);

has 'journal_auth_id' => (
    isa => 'Maybe[Int]',
    is  => 'rw',
);

no Moose;
__PACKAGE__->meta->make_immutable;

1;
