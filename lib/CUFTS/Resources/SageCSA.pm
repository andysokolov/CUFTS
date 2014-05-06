## CUFTS::Resources::SageCSA
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

package CUFTS::Resources::SageCSA;

use base qw(CUFTS::Resources::Base::Journals);

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
            journal_url
        )
    ];
}

## local_resource_details - Controls which details are displayed on the local
## resource pages
##

sub local_resource_details {
    my ($class) = @_;
    return [
        @{ $class->SUPER::local_resource_details },
        qw(
            auth_name
            auth_passwd
            )
    ];
}

## overridable_resource_details - Controls which of the *global* resource details
## are displayed on the *local* resource pages to possibly be overridden
##

sub overridable_resource_details {
    my ($class) = @_;
    return [
        @{ $class->SUPER::overridable_resource_details },
        qw(
            database_url
            )
    ];
}

sub clean_data {
    my ( $class, $record ) = @_;

    $record->{journal_url} =~ s{ username=[^&]+& }{}xsm;
    $record->{journal_url} =~ s{ access=[^&]+&   }{}xsm;
    $record->{journal_url} =~ s{ &mode=all       }{}xsm;

    return $class->SUPER::clean_data($record);
}

## -------------------------------------------------------------------------------------------

## can_get* - Control whether or not an attempt to create a link is built.  This is run
## before the database is searched for possible title matches, so catching requests without
## enough data, etc. early (here) cuts down on database hits

sub can_getFulltext {
    my ( $class, $request ) = @_;

    return 1 if not_empty_string( $request->doi );

    return 1
        if not_empty_string( $request->volume )
        && not_empty_string( $request->issue )
        && not_empty_string( $request->spage );

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
    if (   is_empty_string( $resource->auth_name )
        || is_empty_string( $resource->auth_passwd ) )
    {
        warn( $site->name . ' is using SageCSA without an auth_name and auth_passwd set.' );
        return [];
    }

    my @results;

    foreach my $record (@$records) {
        my $url = $record->journal_url;
        $url .= '&username=' . $resource->auth_name;
        $url .= '&access='   . $resource->auth_passwd;
        $url .= '&mode=pdf';

        if ( not_empty_string( $request->doi ) ) {
            $url .= '&doi=' . uri_escape( $request->doi );
        }
        else {
            $url .= '&volume='    . $request->volume;
            $url .= '&issue='     . $request->issue;
            $url .= '&firstpage=' . $request->spage;
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

    if (   is_empty_string( $resource->auth_name )
        || is_empty_string( $resource->auth_passwd ) )
    {
        warn( $site->name . ' is using SageCSA without an auth_name and auth_passwd set.' );
        return [];
    }

    my @results;

    foreach my $record (@$records) {
        my $url = $record->journal_url;
        $url .= '&username=' . $resource->auth_name;
        $url .= '&access=' . $resource->auth_passwd;
        $url .= '&mode=all';

        my $result = new CUFTS::Result($url);
        $result->record($record);

        push @results, $result;
    }

    return \@results;
}

1;
