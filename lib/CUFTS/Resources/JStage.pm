## CUFTS::Resources::JStage
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

package CUFTS::Resources::JStage;

use base qw(CUFTS::Resources::Base::DOI CUFTS::Resources::Base::Journals);

use CUFTS::Exceptions;
use CUFTS::Util::Simple;

use strict;

sub title_list_fields {
    return [
        qw(
            id
            title
            issn
            e_issn
            ft_start_date
            ft_end_date
            journal_url
            db_identifier
            cjdb_note
        )
    ];
}

sub title_list_field_map {
    return {
        'JOURNAL TITLE'         => 'title',
        'PRINT ISSN'            => 'issn',
        'ONLINE ISSN'           => 'e_issn',
        'RANGE OF STORING FROM' => 'ft_start_date',
        'RANGE OF STORING TO'   => 'ft_end_date',
        'CDJOURNAL'             => 'db_identifier',
        'TOP URL'               => 'journal_url',
    };
}

sub title_list_skip_lines_count { return 1; }

sub clean_data {
    my ( $class, $record ) = @_;

    return $class->SUPER::clean_data($record);
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

sub can_getTOC {
    return 0;
}

sub can_getFulltext {
    my ( $class, $request ) = @_;

    return 0 if is_empty_string( $request->spage );
    return 0 if is_empty_string( $request->volume ) && is_empty_string( $request->issue );

    return $class->SUPER::can_getFulltext($request);
}


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

        my $url = 'http://openurl.jlc.jst.go.jp/servlet/resolver01?genre=article';

        $url .= '&issn=' . dashed_issn( $record->issn );
        $url .= '&spage=' . $request->spage;

        if ( not_empty_string( $request->volume ) ) {
            $url .= '&volume=' . $request->volume;
        }
        if ( not_empty_string( $request->issue ) ) {
            $url .= '&issue=' . $request->issue;
        }

        my $result = new CUFTS::Result($url);
        $result->record($record);

        push @results, $result;
    }

    return \@results;
}

1;
