## CUFTS::Resources::DOAJ
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

package CUFTS::Resources::DOAJ;

use base qw(CUFTS::Resources::Base::Journals);
use Unicode::String qw(utf8);

use String::Util qw( trim hascontent );

use CUFTS::Exceptions;
use CUFTS::Util::Simple;

use strict;

sub title_list_extra_requires {
    require CUFTS::Util::CSVParse;
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
            journal_url
            publisher
        )
    ];
}

## title_list_field_map - Hash ref mapping fields from the raw title lists to
## internal field names
##

sub title_list_field_map {
    return {
        'Title'      => 'title',
        'ISSN'       => 'issn',
        'Start Year' => 'ft_start_date',
        'Identifier' => 'journal_url',
        'Publisher'  => 'publisher',
    };
}

sub title_list_split_row {
    my ( $class, $row ) = @_;

    my $csv = CUFTS::Util::CSVParse->new();

    $csv->parse($row)
        or CUFTS::Exception::App->throw('Error parsing CSV line: ' . $csv->error_input() );


    my @fields = $csv->fields;
    return \@fields;
}

sub clean_data {
    my ( $class, $record ) = @_;

    if ( !defined( $record->{ft_start_date} )
        || $record->{ft_start_date} !~ /^ \d{4} $/xsm )
    {
        delete $record->{ft_start_date};
    }

    $record->{title} =~ s{ \s* \( .+? \) \s* $}{}xsm;
    $record->{title} = trim(utf8( $record->{title} )->latin1);

    if ( !hascontent($record->{title}) ) {
        return [ 'UTF8 conversion removed all latin-1 characters from title, skipping record.'];
    }

    $record->{publisher} = ( utf8( $record->{'publisher'} ) )->latin1;

    $record->{issn} =~ /d\d+/
        and delete $record->{issn};

    return $class->SUPER::clean_data($record);
}

## build_link* - Builds a link to a service.  Should return an array reference containing
## Result objects with urls and title list records (if applicable).
##

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
        my $result = new CUFTS::Result( $record->journal_url );
        $result->record($record);

        push @results, $result;
    }

    return \@results;
}

1;
