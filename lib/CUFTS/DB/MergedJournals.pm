## CUFTS::DB::MergedJournals
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

# This is for accessing a view with basic detail collated
# for searching.

#
# NOTE: This is a view and cannot be updated at this point
#

package CUFTS::DB::MergedJournals;


use CUFTS::Util::Simple;

use strict;
use base 'CUFTS::DB::DBI';

__PACKAGE__->table('merged_journals');
__PACKAGE__->columns(Primary => 'id');
__PACKAGE__->columns(All => qw(
    id

    title
    issn
    e_issn
    site
    resource_name
    local_resource
    global_resource
    active
    vol_cit_start
    vol_cit_end
    vol_ft_start
    vol_ft_end
    iss_cit_start
    iss_cit_end
    iss_ft_start
    iss_ft_end
    cit_start_date
    cit_end_date
    ft_start_date
    ft_end_date
    embargo_months
    embargo_days
    journal_auth

    db_identifier   
    toc_url
    journal_url
    urlbase
    publisher
    abbreviation
    current_months
    current_years
    cjdb_note
    coverage

    erm_main
    erm_main_key
));                      

                                                                                  
__PACKAGE__->columns(Essential => __PACKAGE__->columns);

__PACKAGE__->has_a('erm_main' => 'CUFTS::DB::ERMMain');
__PACKAGE__->has_a('local_resource', 'CUFTS::DB::LocalResources');

1;

