## CUFTS::Resources::OCLC
##
## Copyright Michelle Gauthier - Simon Fraser University (2003-11-27)
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

package CUFTS::Resources::OCLC;

use base qw(CUFTS::Resources::Base::Journals);

use CUFTS::Exceptions;
use CUFTS::Util::Simple;

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
            vol_ft_start
            iss_ft_start
            ft_end_date
            vol_ft_end
            iss_ft_end
            cit_start_date
            vol_cit_start
            iss_cit_start
            cit_end_date
            vol_cit_end
            iss_cit_end
        )
    ];
}

## title_list_field_map - Hash ref mapping fields from the raw title lists to
## internal field names
##

sub title_list_field_map {
    return {
        'Title'                       => 'title',
        'ISSN'                        => 'issn',
        'Citation Begin Year'         => 'cit_start_date',
        'Citation Begin Volume'       => 'vol_cit_start',
        'Citation Begin Issue'        => 'iss_cit_start',
        'Citation Most Recent Year'   => 'cit_end_date',
        'Citation Most Recent Volume' => 'vol_cit_end',
        'Citation Most Recent Issue'  => 'iss_cit_end',
        'Fulltext Begin Year'         => 'ft_start_date',
        'Fulltext Begin Volume'       => 'vol_ft_start',
        'Fulltext Begin Issue'        => 'iss_ft_start',
        'Fulltext Most Recent Year'   => 'ft_end_date',
        'Fulltext Most Recent Volume' => 'vol_ft_end',
        'Fulltext Most Recent Issue'  => 'iss_ft_end',
    };
}

sub title_list_extra_requires {
    require CUFTS::Util::CSVParse;
    require HTML::Entities;
}

sub title_list_split_row {
    my ( $class, $row ) = @_;

    my $csv = CUFTS::Util::CSVParse->new();
    $csv->delim(';');

    $csv->parse($row)
        or CUFTS::Exception::App->throw('Error parsing CSV line: ' . $csv->error_input() );

    my @fields = $csv->fields;
    return \@fields;
}

sub clean_data {
    my ( $class, $record ) = @_;

    foreach my $field ( qw( cit_start_date cit_end_date ft_start_date ft_end_date ) ) {
        next if !defined( $record->{$field} );

        if ( $record->{$field} !~ /^\d{4}$/ ) {
            delete $record->{$field};
        }
    }

    foreach my $field ( qw( vol_ft_start vol_ft_end iss_ft_start iss_ft_end vol_cit_start vol_cit_end iss_cit_start iss_cit_end ) ) {
        next if !defined( $record->{$field} );

        if ( $record->{$field} !~ /^\d+$/ || $record->{$field} eq '0' ) {
            delete $record->{$field};
        }
    }


    $record->{title} = HTML::Entities::decode_entities( $record->{title} );

    return $class->SUPER::clean_data($record);
}

## global_resource_details - Controls which details are displayed on the global
## resource pages
##

sub global_resource_details {
    my ($class) = @_;
    return [
        @{ $class->SUPER::global_resource_details },
        qw( resource_identifier )
    ];
}

sub local_resource_details {
    my ($class) = @_;
    return [
        @{ $class->SUPER::local_resource_details },
        qw( auth_name )
    ];
}

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
        or CUFTS::Exception::App->throw('No site defined in build_linkJournal');
    defined($request)
        or CUFTS::Exception::App->throw('No request defined in build_linkJournal');

    my @results;

    foreach my $record (@$records) {
        next if is_empty_string( $record->issn );

        my $url = 'http://firstsearch.oclc.org/FSIP&dbname=' . $resource->resource_identifier;
        $url .= '&autho=' . $resource->auth_name if $resource->auth_name;
        $url .= '&journal=' . dashed_issn( $record->issn );
        $url .= '&screen=info&done=referer';

        my $result = new CUFTS::Result($url);
        $result->record($record);

        push @results, $result;
    }

    return \@results;
}

sub build_linkDatabase {
    my ( $class, $schema, $records, $resource, $site, $request ) = @_;

    my $db = $resource->resource_identifier or return [];

    my @results;

    foreach my $record (@$records) {
        my $url = 'http://firstsearch.oclc.org/fsip?dbname=' . $db;
        $url .= '&autho=' . $resource->auth_name if $resource->auth_name;

        my $result = new CUFTS::Result($url);
        $result->record($record);

        push @results, $result;
    }

    return \@results;
}

1;
