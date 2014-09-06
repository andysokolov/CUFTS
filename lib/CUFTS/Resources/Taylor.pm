## CUFTS::Resources::Taylor
##
## Copyright Todd Holbrook - Simon Fraser University
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

package CUFTS::Resources::Taylor;

use base qw(CUFTS::Resources::Base::KBART);

use CUFTS::Exceptions;
use CUFTS::Util::Simple;
use URI::Escape qw(uri_escape);

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
            ft_end_date
            vol_ft_start
            vol_ft_end
            iss_ft_start
            iss_ft_end
            journal_url
        )
    ];
}


sub can_getFulltext {
    my ( $class, $request ) = @_;

    return 0 if is_empty_string( $request->spage );

    return $class->SUPER::can_getFulltext($request);
}

sub can_getTOC {
    my ( $class, $request ) = @_;

    return 0
        if is_empty_string( $request->issue )
        && is_empty_string( $request->volume );

    return $class->SUPER::can_getTOC($request);
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

        my $url = 'http://www.tandfonline.com/';

        if ( not_empty_string( $request->doi ) ) {
            $url .= 'doi/full/';
            my $doi = $request->doi;
            $doi =~ s{^doi://}{};
            $url .= $doi;
        }
        else {

            $url .= 'openurl?genre=article';
            $url .= '&issn=' . dashed_issn( $record->issn );
            $url .= '&spage=' . $request->spage;

            if ( not_empty_string( $request->volume ) ) {
                $url .= '&volume=' . $request->volume;
            }
            if ( not_empty_string( $request->issue ) ) {
                my $issue = $request->issue;
                $issue =~ s{/}{-}g; # T&F uses dashes between issues when there's multiples, sometimes we get metadata with slashes though
                $url .= "&issue=${issue}";
            }

        }

        my $result = new CUFTS::Result($url);
        $result->record($record);

        push @results, $result;
    }

    return \@results;
}

sub build_linkTOC {
    my ( $class, $schema, $records, $resource, $site, $request ) = @_;

    defined($records) && scalar(@$records) > 0
        or return [];
    defined($resource)
        or CUFTS::Exception::App->throw('No resource defined in build_linkJournal');
    defined($site)
        or CUFTS::Exception::App->throw('No site defined in build_linkJournal');
    defined($request)
        or CUFTS::Exception::App->throw('No request defined in build_linkJournal');

    my @results;

    foreach my $record (@$records) {

        my $url = 'http://www.tandfonline.com/openurl?genre=article';

        $url .= '&issn=' . dashed_issn( $record->issn );

        if ( not_empty_string( $request->volume ) ) {
            $url .= '&volume=' . $request->volume;
        }
        if ( not_empty_string( $request->issue ) ) {
            $url .= '&issue=' . $request->issue;
        }

        my $result = new CUFTS::Result($url);
        $result->record($record);

        push @results, $result;
    }

    return \@results;
}

1;
