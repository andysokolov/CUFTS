## CUFTS::Resources::GeoScienceWorld
##
## Copyright Michelle Gauthier - Simon Fraser University (2003-11-28)
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

package CUFTS::Resources::GeoScienceWorld;

use base qw(CUFTS::Resources::Base::Journals);

use CUFTS::Exceptions;
use CUFTS::Util::Simple;
use String::Util qw(trim hascontent);
use URI::Escape qw(uri_escape);

use strict;

sub services {
    return [ qw( fulltext journal database ) ];
}

## -------------------------------------------------------------------------------------------

## can_get* - Control whether or not an attempt to create a link is built.  This is run
## before the database is searched for possible title matches, so catching requests without
## enough data, etc. early (here) cuts down on database hits

sub can_getFulltext {
    my ( $class, $request ) = @_;

    return 1 if hascontent( $request->doi );

    return $class->SUPER::can_getFulltext($request);
}


# --------------------------------------------------------------------------------------------

## build_link* - Builds a link to a service.  Should return an array reference containing
## Result objects with urls and title list records (if applicable).
##

sub build_linkFulltext {
    my ( $class, $schema, $records, $resource, $site, $request ) = @_;

    defined($records) && scalar(@$records) > 0
        or return [];
    defined($resource)
        or CUFTS::Exception::App->throw('No resource defined in build_linkFulltext');
    defined($site)
        or CUFTS::Exception::App->throw('No site defined in build_linkFulltext');
    defined($request)
        or CUFTS::Exception::App->throw('No request defined in build_linkFulltext');

    my @results;

    foreach my $record (@$records) {
        my $url = 'http://www.geoscienceworld.org/search?submit=yes&andorexacttitle=and&andorexacttitleabs=and&andorexactfulltext=and&thesaurus=&andorthesaurus=and&affiliation=&meeting_info=&fmonth=&fyear=&tmonth=&tyear=&type=polygon&OpenLayers_Control_LayerSwitcher_22_baseLayers=Google+Hybrid&Selected+Region=Selected+Region&coord_north=90&coord_west=-180&coord_east=180&coord_south=-90&domain=highwire%7Cgeoref&georef_language=all&georef_category=all&georef_biblio_level=all&georef_doc_type_conf=C&georef_doc_type_book=B&georef_doc_type_map=M&georef_doc_type_mtg_abs=mtg_abs&georef_doc_type_report=R&georef_doc_type_jnl_serial=S&georef_doc_type_thesis_diss=T&format=standard&hits=10&sortspec=relevance&group-code=gsw&resourcetype=HWCIT';
        if ( $request->doi ) {
            $url .= '&doi=' . uri_escape($request->doi);
        }
        else {
            $url .= '&doi='       . uri_escape(dashed_issn($record->issn));
            $url .= '&volume='    . uri_escape($request->volume);
            $url .= '&issue='     . uri_escape($request->issue);
            $url .= '&firstpage=' . uri_escape($request->spage);
        }

        my $result = new CUFTS::Result( $url );
        $result->record($record);

        push @results, $result;
    }

    return \@results;
}

1;
