## CUFTS::DB::Sites
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

package CUFTS::DB::Sites;

use strict;
use base 'CUFTS::DB::DBI';

use CUFTS::DB::Accounts_Sites;
use CUFTS::DB::SiteIPs;
use CUFTS::DB::SiteDomains;

__PACKAGE__->table('sites');

__PACKAGE__->columns( Primary => 'id' );
__PACKAGE__->columns(
    All => qw(
        id

        key
        name

        proxy_prefix
        proxy_prefix_alternate
        proxy_WAM
        email
        erm_notification_email

        active

        cjdb_results_per_page
        cjdb_unified_journal_list
        cjdb_show_citations
        cjdb_hide_citation_coverage
        cjdb_display_db_name_only
        cjdb_print_name
        cjdb_print_link_label

        cjdb_authentication_module
        cjdb_authentication_server
        cjdb_authentication_string1
        cjdb_authentication_string2
        cjdb_authentication_string3
        cjdb_authentication_level100
        cjdb_authentication_level50

        marc_dump_856_link_label
        marc_dump_duplicate_title_field
        marc_dump_cjdb_id_field
        marc_dump_cjdb_id_indicator1
        marc_dump_cjdb_id_indicator2
        marc_dump_cjdb_id_subfield
        marc_dump_holdings_field
        marc_dump_holdings_indicator1
        marc_dump_holdings_indicator2
        marc_dump_holdings_subfield
        marc_dump_medium_text
        marc_dump_direct_links

        rebuild_cjdb
        rebuild_MARC
        rebuild_ejournals_only
        show_ERM
        test_MARC_file
        
        google_scholar_on
        google_scholar_keywords
        google_scholar_e_link_label
        google_scholar_other_link_label
        google_scholar_openurl_base
        google_scholar_other_xml


        created
        modified

        )
);

__PACKAGE__->columns( Essential => qw(
    id

    key
    name

    proxy_prefix
    proxy_prefix_alternate
    proxy_WAM
    email

    cjdb_authentication_module
    cjdb_authentication_server
    cjdb_results_per_page
    cjdb_unified_journal_list
    cjdb_show_citations
    cjdb_hide_citation_coverage

    active

    created
    modified
));

__PACKAGE__->sequence('sites_id_seq');

__PACKAGE__->has_many( 'accounts', [ 'CUFTS::DB::Accounts_Sites' => 'account' ], 'site' );
__PACKAGE__->has_many( 'ips'     => 'CUFTS::DB::SiteIPs' );
__PACKAGE__->has_many( 'domains' => 'CUFTS::DB::SiteDomains' );

1;
