## CUFTS::Resources::NRC
##
## Copyright Michelle Gauthier - Simon Fraser University (2004-02-04)
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

package CUFTS::Resources::NRC;

use base qw(CUFTS::Resources::Base::Journals);

use CUFTS::Exceptions;
use CUFTS::Util::Simple;

use strict;

sub services {
    return [ qw( fulltext journal database ) ];
}

## title_list_fields - Controls what fields get displayed and loaded from
## title lists.
##

sub title_list_fields {
    return [
        qw(
            id
            title
            issn
            e_issn
            ft_start_date
            vol_ft_start
            iss_ft_start
            ft_end_date
            vol_ft_end
            iss_ft_end
            journal_url
        )
    ];
}

## -------------------------------------------------------------------------------------------

## can_get* - Control whether or not an attempt to create a link is built.  This is run
## before the database is searched for possible title matches, so catching requests without
## enough data, etc. early (here) cuts down on database hits

sub can_getFulltext {
    my ( $class, $request ) = @_;

    return 0
        if is_empty_string( $request->spage );

    return $class->SUPER::can_getFulltext($request);
}

sub can_getTOC {
    my ( $class, $request ) = @_;

    return 0;
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
        next if is_empty_string( $record->issn );

        my $url = 'http://article.pubs.nrc-cnrc.gc.ca/ppv/RPViewDoc?' . 'issn=';
        $url .= dashed_issn( $record->issn );
        $url .= '&volume='    . $request->volume;
        $url .= '&issue='     . $request->issue;
        $url .= '&startPage=' . $request->spage;

        my $result = new CUFTS::Result($url);
        $result->record($record);

        push @results, $result;
    }
    return \@results;
}

1;
