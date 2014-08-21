## CUFTS::Resources::Factiva
##
## Copyright Michelle Gauthier - Simon Fraser University (2003-10-28)
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

package CUFTS::Resources::Factiva;

use base qw(CUFTS::Resources::Base::Journals);

use CUFTS::Exceptions;
use CUFTS::Util::Simple;
use String::Util qw(hascontent trim);
use Unicode::String qw(utf8);
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
            ft_start_date
            ft_end_date
            db_identifier
            cjdb_note
            journal_auth
        )
    ];
}

## title_list_field_map - Hash ref mapping fields from the raw title lists to
## internal field names
##

sub title_list_field_map {
    return {
        'Source Code (sc)'                       => 'db_identifier',
        'Directory Name (dn)'                    => 'title',
        'ISSN (isn)'                             => 'issn',
        'First Issue Online (fio)'               => 'ft_start_date',
        'Discontinued Date (dsd)'                => 'ft_end_date',
        'Type of  Coverage - Source Level (lvs)' => '___source_level',
    };
}


sub local_resource_details {
    my ($class) = @_;
    return [
        @{ $class->SUPER::local_resource_details },
        qw( auth_name )
    ];
}


sub clean_data {
    my ( $class, $record ) = @_;

    if ( hascontent($record->{ft_start_date}) && $record->{ft_start_date} =~ /^(\d{4})(\d{2})(\d{2})$/ ) {
        $record->{ft_start_date} = "$1-$2-$3";
    }
    if ( hascontent($record->{ft_end_date}) && $record->{ft_end_date} =~ /^(\d{4})(\d{2})(\d{2})$/ ) {
        $record->{ft_end_date} = "$1-$2-$3";
    }

    if ( $record->{'___source_level'} eq 'Selected Coverage' ) {
        $record->{cjdb_note} = 'Selected coverage.';
    }

    $record->{title} = utf8($record->{title})->latin1;
    $record->{title} = trim_string($record->{title}, '"');

    delete $record->{issn} if $record->{issn} !~ /^\d{4}-\d{3}[\dxX]$/;
}

## -------------------------------------------------------------------------------------------

## can_get* - Control whether or not an attempt to create a link is built.  This is run
## before the database is searched for possible title matches, so catching requests without
## enough data, etc. early (here) cuts down on database hits

sub can_getFulltext {
    my ( $class, $request ) = @_;

    return 0 if !hascontent( $request->spage ) && !hascontent( $request->atitle );

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

        my $url = 'https://global.factiva.com/redir/default.aspx?p=ou&XSID=' . uri_escape($resource->auth_name);

        if ( hascontent($record->issn) ) {
            $url .= '&issn=' . dashed_issn( $record->issn );
        }
        if ( hascontent($request->volume) ) {
            $url .= '&volume=' . $request->volume;
        }
        if ( hascontent($request->issue) ) {
            $url .= '&issue=' . $request->issue;
        }
        if ( hascontent($request->spage) ) {
            $url .= '&spage=' . $request->spage;
        }
        if ( hascontent($request->date) && $request->date =~ /^\d{4}-\d{2}-\d{2}$/ ) {
            $url .= '&date=' . $request->date;
        }
        if ( hascontent($request->atitle) ) {
            $url .= '&atitle=' . uri_escape($request->atitle);
        }
        $url .= '&title=' . uri_escape($record->title);

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
        my $url = 'https://global.factiva.com/en/du/headlines.asp?searchText=rst%3D' . uri_escape($record->db_identifier) . '&XSID=' . uri_escape($resource->auth_name);
        my $result = new CUFTS::Result($url);
        $result->record($record);

        push @results, $result;
    }

    return \@results;
}

1;
