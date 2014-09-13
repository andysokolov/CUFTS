## CUFTS::Resources::OvidLinking
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

package CUFTS::Resources::OvidLinking;

use base qw(CUFTS::Resources::Base::Journals);

use CUFTS::Exceptions;
use CUFTS::Util::Simple;
use URI::Escape;

use strict;

sub services {
    return [ qw( fulltext journal database ) ];
}

my $default_url_base = 'gateway.ovid.com';

## title_list_fields - Controls what fields get displayed and loaded from
## title lists.
##

sub title_list_fields {
    return [
        qw(
            id
            title
            issn

            ft_start_date
            ft_end_date
            vol_ft_start
            vol_ft_end
            iss_ft_start
            iss_ft_end

            publisher

            journal_url
        )
    ];
}

## global_resource_details - Controls which details are displayed on the global
## resource pages
##

sub global_resource_details {
    my ($class) = @_;
    return [    #@{$class->SUPER::global_resource_details},
        qw(
            resource_identifier
            url_base
        )
    ];
}

# overridable_resource_details - Controls which of the *global* resource details
## are displayed on the *local* resource pages to possibly be overridden
##

sub overridable_resource_details {
    my ($class) = @_;
    return [
        @{ $class->SUPER::overridable_resource_details },
        qw(
            database_url
            url_base
        )
    ];
}

sub local_resource_details {
    my ($class) = @_;
    return [
        @{ $class->SUPER::local_resource_details },
        qw(
            url_base
        )
    ];
}

## help_template - path to the help template for this resource relative to the
## general templates directory
##

sub help_template {
    return 'help/Ovid';
}

## resource_details_help - A hash ref containing the hoverover help for each of the
## local resource details
##

sub resource_details_help {
    my ($class) = @_;

    my $help_hash = $class->SUPER::resource_details_help;
    $help_hash->{'url_base'} = 'The address of your Ovid Web Gateway. Required for linking.';

    return $help_hash;
}

## -------------------------------------------------------------------------------------------

## can_get* - Control whether or not an attempt to create a link is built.  This is run
## before the database is searched for possible title matches, so catching requests without
## enough data, etc. early (here) cuts down on database hits

sub can_getFulltext {
    my ( $class, $request ) = @_;

    if (
         (    is_empty_string( $request->volume )
           || is_empty_string( $request->issue  )
           || is_empty_string( $request->spage  )
         )
         && is_empty_string( $request->atitle )
       )
    {
        return 0
    }

    return 1;
}

sub can_getTOC {
    my ( $class, $request ) = @_;

    if (    is_empty_string( $request->volume )
         || is_empty_string( $request->issue  )
    ) {
        return 0
    }

    return 1;
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
        my $url_base = $resource->url_base || $default_url_base;

        my $url = "http://${url_base}/ovidweb.cgi?T=JS&MODE=ovid&NEWS=n&PAGE=fulltext";
        $url .= '&D=' . $resource->resource_identifier . '&SEARCH=';

        if ( not_empty_string( $record->issn ) ) {
            $url .= substr( $record->issn, 0, 4 ) . '-' . substr( $record->issn, 4, 4 ) . '.IS+and+';
        }
        else {
            $url .= uri_escape($record->title) . '.JN+and+';
        }

        if (    is_empty_string( $request->volume )
             || is_empty_string( $request->issue  )
             || is_empty_string( $request->spage  ) )
        {
            my $atitle = $request->atitle;
            $atitle =~ s/\.$//;
            $url .= uri_escape($atitle) . '.TI';
        }
        else {
            $url .= $request->volume . '.VO+and+'
                  . $request->issue  . '.IP+and+'
                  . $request->spage  . '.PG';
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
        or CUFTS::Exception::App->throw('No resource defined in build_linkTOC');
    defined($site)
        or CUFTS::Exception::App->throw('No site defined in build_linkTOC');
    defined($request)
        or CUFTS::Exception::App->throw('No request defined in build_linkTOC');

    my @results;

    foreach my $record (@$records) {
        my $url_base = $resource->url_base || $default_url_base;

        my $url = "http://${url_base}/ovidweb.cgi?T=JS&MODE=ovid&NEWS=n&PAGE=TOC";
        $url .= '&D=' . $resource->resource_identifier . '&SEARCH=';

        if ( not_empty_string( $record->issn ) ) {
            $url .= substr( $record->issn, 0, 4 ) . '-' . substr( $record->issn, 4, 4 )
                . '.IS+and+';
        }
        else {
            $url .= uri_escape($record->title) . '.JN+and+';
        }

        $url .= $request->volume . '.VO+and+'
              . $request->issue  . '.IP';

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

        my $url;

        if ( not_empty_string($record->journal_url ) ) {
            $url = $record->journal_url;
        }
        else {
            my $url_base = $resource->url_base || $default_url_base;

            $url = "http://${url_base}/ovidweb.cgi?T=JS&MODE=ovid&NEWS=n&PAGE=TOC";
            $url .= '&D=' . $resource->resource_identifier . '&SEARCH=';

            if ( not_empty_string( $record->issn ) ) {
                $url .= substr( $record->issn, 0, 4 ) . '-' . substr( $record->issn, 4, 4 ) . '.IS';
            }
            else {
                $url .= uri_escape($record->title) . '.JN';
            }

        }

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
        or CUFTS::Exception::App->throw('No resource defined in build_linkJournal');
    defined($site)
        or CUFTS::Exception::App->throw('No site defined in build_linkJournal');
    defined($request)
        or CUFTS::Exception::App->throw('No request defined in build_linkJournal');

    my @results;

    foreach my $record (@$records) {

        my $url;

        if ( not_empty_string($resource->database_url ) ) {
            $url = $resource->database_url;
        }
        else {
            my $url_base = $resource->url_base || $default_url_base;

            $url = "http://${url_base}/ovidweb.cgi?T=JS&MODE=ovid&NEWS=n&PAGE=main";
            $url .= '&D=' . $resource->resource_identifier;
        }

        my $result = new CUFTS::Result($url);
        $result->record($record);

        push @results, $result;

    }

    return \@results;

}

1;
