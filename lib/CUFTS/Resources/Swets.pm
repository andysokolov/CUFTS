## CUFTS::Resources::Swets
##
## Copyright Todd Holbrook - Simon Fraser University (2003-11-05)
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

package CUFTS::Resources::Swets;

use base qw(CUFTS::Resources::Base::Journals);

use CUFTS::Exceptions;
use CUFTS::Util::Simple;

use strict;

sub services {
    return [ qw( fulltext journal database ) ];
}

my $url_base = 'http://www.swetswise.com/link/access_db?';

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
            publisher
        )
    ];
}

## title_list_field_map - Hash ref mapping fields from the raw title lists to
## internal field names
##

sub title_list_field_map {

    return {
        'TITLE'       => 'title',
        'ISSN 1'      => 'issn',
        'ISSN 2'      => 'e_issn',
        'START YEAR'  => 'ft_start_date',
        'CEASED YEAR' => 'ft_end_date',
        'FIRST VOL'   => 'vol_ft_start',
        'LAST VOL'    => 'vol_ft_end',
        'FIRST ISS'   => 'iss_ft_start',
        'LAST ISS'    => 'iss_ft_end',
        'PUBLISHER'   => 'publisher',
    };
}

sub title_list_extra_requires {
    require Text::CSV;
}

sub title_list_split_row {
    my ( $class, $row ) = @_;

    my $csv = Text::CSV->new();
    $csv->parse($row)
        or CUFTS::Exception::App->throw('Error parsing CSV line: ' . $csv->error_input() );

    my @fields = $csv->fields;
    return \@fields;
}

sub clean_data {
    my ( $class, $record ) = @_;

    # int each field and delete if it is 0

    foreach my $field ( qw( ft_start_date ft_end_date vol_ft_start vol_ft_end iss_ft_start iss_ft_end ) ) {
        if ( defined($record->{$field}) ) {

            $record->{$field} = int( $record->{$field} );
            if ( $record->{$field} == 0 ) {
                delete $record->{$field};
            }

        }
    }

    # Check that dates make sense.. sometimes there are bad dates like "0410"

    if ( defined($record->{ft_start_date}) && $record->{ft_start_date} !~ /^(19|20)/ ) {
        return [ 'Invalid date: ' . $record->{ft_start_date} ];
    }

    if ( defined($record->{ft_end_date}) && $record->{ft_end_date} !~ /^(18|19|20)/ ) {
        return [ 'Invalid date: ' . $record->{ft_end_date} ];
    }

    # Clear vol/iss ends unless the journal is really ending (has a ft end date)

    if ( is_empty_string( $record->{ft_end_date} ) ) {
            delete $record->{ft_end_date};
            delete $record->{vol_ft_end};
            delete $record->{iss_ft_end};
    }

    # Remove the electronic ISSN field if it is a duplicate of the ISSN

    if ( $record->{e_issn} eq $record->{issn} ) {
        delete $record->{e_issn};
    }

    return $class->SUPER::clean_data($record);
}

## -------------------------------------------------------------------------------------------

## can_get* - Control whether or not an attempt to create a link is built.  This is run
## before the database is searched for possible title matches, so catching requests without
## enough data, etc. early (here) cuts down on database hits

sub can_getFulltext {
    my ( $class, $request ) = @_;

    return 0
        if is_empty_string( $request->spage  )
        || is_empty_string( $request->issue  )
        || is_empty_string( $request->volume );

    return $class->SUPER::can_getFulltext($request);
}

sub can_getTOC {
    my ( $class, $request ) = @_;

    return 0
        if is_empty_string( $request->issue  )
        || is_empty_string( $request->volume );

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
        my $issn = $record->issn || $record->e_issn;
        next if is_empty_string( $issn );

        my $url = $url_base . "issn=$issn";
        $url .= '&vol=' . $request->volume . '&iss=' . $request->issue;
        $url .= '&page=' . $request->spage . '&FT=1';

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
        my $issn = $record->issn || $record->e_issn;
        next if is_empty_string( $issn );

        my $url = $url_base . "issn=$issn";
        $url .= '&vol=' . $request->volume . '&iss=' . $request->issue;

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
        my $issn = $record->issn || $record->e_issn;
        next if is_empty_string( $issn );

        my $result = new CUFTS::Result( $url_base . "issn=$issn" );
        $result->record($record);

        push @results, $result;
    }

    return \@results;
}

1;
