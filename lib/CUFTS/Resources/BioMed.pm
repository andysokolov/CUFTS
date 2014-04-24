## CUFTS::Resources::BioMed
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

package CUFTS::Resources::BioMed;

use base qw(CUFTS::Resources::Base::DOI CUFTS::Resources::Base::Journals);

use CUFTS::Exceptions;
use CUFTS::Util::Simple;

use strict;

sub title_list_extra_requires {
    require Text::CSV;
}

## title_list_fields - Controls what fields get displayed and loaded from
## title lists.

sub title_list_fields {
    return [
        qw(
            id
            title
            abbreviation
            issn
            ft_start_date
            journal_url
        )
    ];
}

sub title_list_field_map {
    return {
        'Journal name' => 'title',
        'Abbreviation' => 'abbreviation',
        'ISSN'         => 'issn',
        'URL'          => 'journal_url',
        'Start Date'   => 'ft_start_date'
    };
}

sub title_list_split_row {
    my ( $class, $row ) = @_;

    my $csv = Text::CSV->new();
    $csv->parse($row)
        or CUFTS::Exception::App->throw( 'Error parsing CSV line: ' . $csv->error_input() );

    my @fields = $csv->fields;
    return \@fields;
}

sub clean_data {
    my ( $class, $record ) = @_;

    if ( $record->{'issn'} eq 'n/a' ) {
        delete $record->{'issn'};
    }

    return $class->SUPER::clean_data($record);
}

# --------------------------------------------------------------------------------------------

## build_link* - Builds a link to a service.  Should return an array reference containing
## Result objects with urls and title list records (if applicable).
##

sub build_linkJournal {
    my ( $class, $schema, $records, $resource, $site, $request ) = @_;

    defined($records) && scalar(@$records) > 0
        or return [];
    defined($resource)
        or CUFTS::Exception::App->throw('No resource defined in build_linkJournal');
    defined($site)
        or
        CUFTS::Exception::App->throw('No site defined in build_linkJournal');
    defined($request)
        or CUFTS::Exception::App->throw('No request defined in build_linkJournal');

    my @results;

    foreach my $record (@$records) {

        my $result = new CUFTS::Result($record->journal_url);
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

        my $url = $resource->database_url
                  || 'http://www.biomedcentral.com/search/';

        my $result = new CUFTS::Result($url);
        $result->record($record);

        push @results, $result;
    }

    return \@results;
}

1;
