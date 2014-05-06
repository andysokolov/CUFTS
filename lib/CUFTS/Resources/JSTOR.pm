## CUFTS::Resources::JSTOR
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

package CUFTS::Resources::JSTOR;

use base qw(CUFTS::Resources::Base::KBART);

use CUFTS::Exceptions;
use CUFTS::Util::Simple;
use URI::Escape qw(uri_escape);
use Unicode::String qw(utf8);
use String::Util qw(hascontent);

use strict;

sub services {
    return [ qw( fulltext journal database ) ];
}

my $base_url = 'http://makealink.jstor.org/public-tools/GetURL?';

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
            iss_ft_start
            vol_ft_end
            iss_ft_end
            journal_url
            publisher
        )
    ];
}

sub title_list_read_row {
    my ($class, $IN) = @_;
    my $text = <$IN>;
    return undef if !hascontent($text);
    my $text2 = '' . utf8($text)->latin1;
    return $text2;
}

sub clean_data {
    my ( $class, $record ) = @_;

    return $class->SUPER::clean_data($record);

}

# -----------------------------------------------------------------------

sub can_getFulltext {
    my ( $class, $request ) = @_;

    return 0 if is_empty_string( $request->spage );
    return 0 if is_empty_string( $request->volume );
    return $class->SUPER::can_getFulltext($request);
}

sub build_linkFulltext {
    my ( $class, $schema, $records, $resource, $site, $request ) = @_;

    my @skip_issue_in_sici = qw( 00664162 1543592X );

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
        next if is_empty_string( $record->issn );

        # Build a SICI for linking

        # http://links.jstor.org/sici?sici=0090-5364%28198603%2914%3A1%3C1%3AOTCOBE%3E2.0.CO%3B2-U
        # Abstract from Lynch, Clifford A. “The Integrity of Digital Information; Mechanics and Definitional Issues.” JASIS 45:10 (Dec. 1994) p. 737-44
        # 0002-8231(199412)45:10<737:TIODIM>2.3.TX;2-M
        # http://makealink.jstor.org/public-tools/GetURL?volume=54&issue=8&date=19701201&journal_title=00267902&page=562
        # http://links.jstor.org/sici?sici=00267902%281970%2954:8%3A8%3C562%3E2.3.TX

        my $volume = $request->volume;
        $volume =~ s/^suppl?\s*//i;

        my $issue = $request->issue;
        $issue =~ s/^suppl?\s*//i;

        my $sici = $record->issn;

        $sici .= '(' . $request->year . $request->month . ')';
        $sici .= $volume;
        if ( not_empty_string( $issue ) && !grep { $_ eq $record->issn } @skip_issue_in_sici ) {
            $sici .= ':' . $issue;
        }
        $sici .= '<' . $request->spage . '>';
        $sici .= '2.3.TX';  # ??

        my $url = 'http://links.jstor.org/sici?sici=' . uri_escape($sici);

        my $result = new CUFTS::Result($url);
        $result->record($record);

        push @results, $result;
    }

    return \@results;
}

sub can_getTOC {
    my ( $class, $request ) = @_;

    return 0;   # Turn off for now until I can figure out if it works with SICI style links

    return 0
        if is_empty_string( $request->volume )
        || is_empty_string( $request->issue  )
        || is_empty_string( $request->date   );

    return $class->SUPER::can_getTOC($request);
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
        next if is_empty_string( $record->issn );

        my @params;
        if ( not_empty_string($request->volume) ) {
            push @params, 'volume=' . $request->volume;
        }
        if ( not_empty_string($request->issue) ) {
            push @params, 'issue=' . $request->issue;
        }

        if (     is_empty_string( $request->volume )
             &&  is_empty_string( $request->issue  )
             && not_empty_string( $request->date   ) )
        {
            push @params, 'date=' . $request->date;
        }

        push @params, 'issn=' . $record->issn;

        my $url = $base_url;
        $url .= join '&', @params;

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

        my $url = $record->journal_url;
        if ( is_empty_string($url) ) {
            next if is_empty_string( $record->issn );
            $url = 'http://www.jstor.org/journals/' . $record->issn . '.html';
        }

        my $result = new CUFTS::Result($url);
        $result->record($record);

        push @results, $result;
    }

    return \@results;
}

1;
