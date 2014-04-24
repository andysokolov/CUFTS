## CUFTS::Resources::History_Coop
##
## Copyright Michelle Gauthier - Simon Fraser University (2004-03-31)
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

package CUFTS::Resources::History_Coop;

use base qw(CUFTS::Resources::Base::Journals);

use CUFTS::Exceptions;
use CUFTS::Util::Simple;

use strict;

my $url_base = 'http://www.historycooperative.org/';

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
            db_identifier
        )
    ];
}

## -------------------------------------------------------------------------------------------

## can_get* - Control whether or not an attempt to create a link is built.  This is run
## before the database is searched for possible title matches, so catching requests without
## enough data, etc. early (here) cuts down on database hits

sub can_getTOC {
    my ( $class, $request ) = @_;

    return 0 if is_empty_string( $request->volume );

    return $class->SUPER::can_getTOC($request);
}

# --------------------------------------------------------------------------------------------

## build_link* - Builds a link to a service.  Should return an array reference containing
## Result objects with urls and title list records (if applicable).
##

sub build_linkTOC {
    my ( $class, $schema, $records, $resource, $site, $request ) = @_;

    defined($records) && scalar(@$records) > 0
        or return [];
    defined($resource)
        or CUFTS::Exception::App->throw('No resource defined in build_linkTOC');
    defined($site)
        or CUFTS::Exception::App->throw('No site defined in build_linkTOC');
    defined($request)
        or CUFTS::Exception::App->throw('No request defined in build_linkTOC');

    my @results;

    foreach my $record (@$records) {
        my $issn = $record->issn;
        next if is_empty_string($issn);

        next if  !$request->issue
              && ( $issn ne '00236942' || $issn ne '07003862' );

        my $url = $url_base . 'journals/' . $record->db_identifier . '/';

        if ( $issn eq '1544824X' ) {
            # one journal has a different syntax
            $url .= 'vol-' . sprintf( "%02u", $request->volume ) . '/';
            $url .= 'no-'  . sprintf( "%02u", $request->issue  ) . '/';
        }
        else {
            $url .= $request->volume;
            if ( $request->issue ) {
                $url .= '.' . $request->issue;
            }
        }

        my $result = new CUFTS::Result($url);
        $result->record($record);

        push @results, $result;
    }

    return \@results;
}

sub build_linkJournal {
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

        my $url = $url_base . $record->db_identifier . 'index.html';

        my $result = new CUFTS::Result($url);
        $result->record($record);

        push @results, $result;
    }

    return \@results;
}

sub build_linkDatabase {
    my ( $class, $schema, $records, $resource, $site, $request ) = @_;

    defined($records) && scalar(@$records) > 0
        or return [];
    defined($resource)
        or CUFTS::Exception::App->throw('No resource defined in build_linkDatabase');
    defined($site)
        or CUFTS::Exception::App->throw('No site defined in build_linkDatabase');
    defined($request)
        or CUFTS::Exception::App->throw('No request defined in build_linkDatabase');

    my @results;

    foreach my $record (@$records) {
        my $result = new CUFTS::Result( $url_base . 'search.html' );
        $result->record($record);

        push @results, $result;
    }

    return \@results;
}

1;
