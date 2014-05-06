## CUFTS::Resources::deGruyter
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

package CUFTS::Resources::deGruyter;

use base qw(CUFTS::Resources::Base::SFXLoader);

use CUFTS::Exceptions;
use CUFTS::Util::Simple;
use URI::Escape;
use Unicode::String qw(utf8);

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

# Last version of the title list had no extra first line like most SFX Lists have.

# sub title_list_skip_lines_count { return 0; }

sub clean_data {
    my ( $class, $record ) = @_;

    $record->{title} = utf8( $record->{title} )->latin1;

    return $class->SUPER::clean_data( $record );
}

## -------------------------------------------------------------------------------------------

## can_get* - Control whether or not an attempt to create a link is built.  This is run
## before the database is searched for possible title matches, so catching requests without
## enough data, etc. early (here) cuts down on database hits

sub can_getFulltext {
    my ($class, $request) = @_;

    return 1 if not_empty_string($request->doi);
    return 0;
}

# --------------------------------------------------------------------------------------------

## build_link* - Builds a link to a service.  Should return an array reference containing
## Result objects with urls and title list records (if applicable).
##

sub build_linkFulltext {
    my ($class, $schema, $records, $resource, $site, $request) = @_;

    defined($records) && scalar(@$records) > 0 or
        return [];
    defined($resource) or
        CUFTS::Exception::App->throw('No resource defined in build_linkFulltext');
    defined($site) or
        CUFTS::Exception::App->throw('No site defined in build_linkFulltext');
    defined($request) or
        CUFTS::Exception::App->throw('No request defined in build_linkFulltext');

    if ( is_empty_string($request->doi) ) {
        return [];
    }

    my @results;
    foreach my $record (@$records) {
        my $url = 'http://www.reference-global.com/doi/pdf/';
        $url .= uri_escape($request->doi, "^A-Za-z0-9\-_.!~*'()\/");

        my $result = new CUFTS::Result($url);
        $result->record($records->[0]);

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
        next if is_empty_string( $record->journal_url );

        my $result = new CUFTS::Result( $record->journal_url );
        $result->record($record);

        push @results, $result;
    }

    return \@results;
}


1;
