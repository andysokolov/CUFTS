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

use strict;

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
        )
    ];
}

## title_list_field_map - Hash ref mapping fields from the raw title lists to
## internal field names
##

sub title_list_field_map {
    return {
        'Directory Name (dn)'                    => 'title',
        'ISSN (isn)'                             => 'issn',
        'First Issue Online (fio)'               => 'ft_start_date',
        'Discontinued Date (dsd)'                => 'ft_end_date',
        'Type of  Coverage - Source Level (lvs)' => '___source_level',
    };
}


sub clean_data {
    my ( $class, $record ) = @_;

    if ( hascontent($record->{ft_start_date}) && $record->{ft_start_date} =~ /^(\d{4})(\d{2})(\d{2})$/ ) {
        $record->{ft_start_date} = "$1-$2-$3";
    }
    if ( hascontent($record->{ft_end_date}) && $record->{ft_end_date} =~ /^(\d{4})(\d{2})(\d{2})$/ ) {
        $record->{ft_end_date} = "$1-$2-$3";
    }

    $record->{cjdb_note} = 'Links to database search only.';

    if ( $record->{'___source_level'} eq 'Selected Coverage' ) {
        $record->{cjdb_note} = 'Selected coverage. ' . $record->{cjdb_note};
    }

}

## -------------------------------------------------------------------------------------------

## can_get* - Control whether or not an attempt to create a link is built.  This is run
## before the database is searched for possible title matches, so catching requests without
## enough data, etc. early (here) cuts down on database hits

sub can_getFulltext {
    my ( $class, $request ) = @_;

    return 0 if is_empty_string( $request->spage );

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
    my ( $class, $records, $resource, $site, $request ) = @_;

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

        next if is_empty_string( $record->issn   )
             && is_empty_string( $record->e_issn );

        my $url = 'http://global.factiva.com/redir/default.aspx?p=ou&';

        if ( $record->issn ) {
            $url .= 'issn=' . dashed_issn( $record->issn );
        }

        $url .= '&volume=' . $request->volume
              . '&issue='  . $request->issue
              . '&spage='  . $request->spage;

        my $result = new CUFTS::Result($url);
        $result->record($record);

        push @results, $result;
    }

    return \@results;
}

sub build_linkJournal {
    my ( $class, $records, $resource, $site, $request ) = @_;

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
        my $result = new CUFTS::Result('http://global.factiva.com/');
        $result->record($record);

        push @results, $result;
    }

    return \@results;
}

1;
