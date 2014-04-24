## CUFTS::Resources::Elsevier_CNSLP
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

package CUFTS::Resources::Elsevier_CNSLP;

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
            ft_start_date
            vol_ft_start
            iss_ft_start
            ft_end_date
            vol_ft_end
            iss_ft_end
            journal_url
            current_months
        )
    ];
}

sub title_list_field_map {
    return {
        'Journal Title' => 'title',
        'ISSN'          => 'issn',
        'Doc URL'       => 'journal_url',
    };
}

sub clean_data {
    my ( $class, $record ) = @_;

    $record->{title} =~ s/^\s*"\s*//;
    $record->{title} =~ s/\s*"\s*$//;

    my ( $start, $end );

    if ( $record->{'___Date Coverage'} =~ /^ ( .+ (?: \) ) )  \s* - \s*  (.+) $/xsm ) {
        ( $start, $end ) = ( $1, $2 );
    }
    elsif ( $record->{'___Date Coverage'} =~ /^ ( .+ (?: \d ) )  \s+ - \s*  (.+) $/xsm ) {
        ( $start, $end ) = ( $1, $2 );
    }
    elsif ( $record->{'___Date Coverage'} =~ /^ ( .+ (?:\d) )  \s* - \s*  ( (?:v) .+ ) $/xsm )
    {
        ( $start, $end ) = ( $1, $2 );
    }
    else {
        $start = $record->{'___Date Coverage'};
    }

    if ( defined($start) ) {
        if ( $start =~ /v\.?\s*(\d+)/i ) {
            $record->{vol_ft_start} = $1;
        }
        if ( $start =~ /n\.?\s*(\d+)/i ) {
            $record->{iss_ft_start} = $1;
        }
        if ( $start =~ / \( \s* (\d+) \s+ (\w+) \s+ (\d+) \s* \) /xsm ) {
            my ( $day, $month, $year ) = ( $1, $2, $3 );
            $month = get_month( $month, 'start' );
            $record->{ft_start_date} = sprintf( "%04d-%02d-%02d", $year, $month, $day );
        }
        elsif ( $start =~ / \( \s* ([a-zA-Z]+) \s* -? \s* [a-zA-Z]* \s+ (\d+) \s* \) /xsm )
        {
            my ( $month, $year ) = ( $1, $2 );
            $month = get_month( $month, 'start' );
            $record->{ft_start_date} = sprintf( "%04d-%02d", $year, $month );
        }
        elsif ( $start =~ / \( \s* (\d+) /xsm ) {
            $record->{ft_start_date} = $1;
        }
        elsif ( $start =~ / (\d{4}) $/xsm ) {
            $record->{ft_start_date} = $1;
        }
    }

    if ( defined($end) && $end ne 'onwards' ) {
        if ( $end =~ / v\.? \s* \d+ \s* - \s* (\d+) /xsmi ) {
            $record->{vol_ft_end} = $1;
        }
        elsif ( $end =~ / v\.? \s* (\d+) /xsmi ) {
            $record->{vol_ft_end} = $1;
        }
        elsif ( $end =~ / \d{1,4} \D /xsm ) {
            $record->{vol_ft_end} = $1;
        }
        if ( $end =~ / n\.? \s* \d+ \s* - \s* (\d+) /xsmi ) {
            $record->{iss_ft_end} = $1;
        }
        elsif ( $end =~ /n\.?\s*(\d+)/ ) {
            $record->{iss_ft_end} = $1;
        }
        if ( $end =~ / \( \s* (\d+) \s+ (\w+) \s+ (\d+) \s* \) /xsmi ) {
            my ( $day, $month, $year ) = ( $1, $2, $3 );
            $month = get_month( $month, 'end' );
            $record->{ft_end_date} = sprintf( "%04d-%02d-%02d", $year, $month, $day );
        }
        elsif ( $end =~ / \( \s* [a-zA-Z]*? \s* -? \s* ([a-zA-Z]+) \s+ (\d+) \s* \) /xsm ) {
            my ( $month, $year ) = ( $1, $2 );
            $month = get_month( $month, 'end' );
            $record->{'ft_end_date'} = sprintf( "%04d-%02d", $year, $month );
        }
        elsif ( $end =~ /(\d+)\s*\)/i ) {
            $record->{ft_end_date} = $1;
        }
    }
    return $class->SUPER::clean_data($record);

    sub get_month {
        my ( $month, $period ) = @_;

        if    ( $month =~ /^Jan/i ) { return 1 }
        elsif ( $month =~ /^Feb/i ) { return 2 }
        elsif ( $month =~ /^Mar/i ) { return 3 }
        elsif ( $month =~ /^Apr/i ) { return 4 }
        elsif ( $month =~ /^May/i ) { return 5 }
        elsif ( $month =~ /^Jun/i ) { return 6 }
        elsif ( $month =~ /^Jul/i ) { return 7 }
        elsif ( $month =~ /^Aug/i ) { return 8 }
        elsif ( $month =~ /^Sep/i ) { return 9 }
        elsif ( $month =~ /^Oct/i ) { return 10 }
        elsif ( $month =~ /^Nov/i ) { return 11 }
        elsif ( $month =~ /^Dec/i ) { return 12 }
        elsif ( $month =~ /^Spr/i ) { return $period eq 'start' ? 1 : 6 }
        elsif ( $month =~ /^Sum/i ) { return $period eq 'start' ? 3 : 9 }
        elsif ( $month =~ /^Fal/i ) { return $period eq 'start' ? 6 : 12 }
        elsif ( $month =~ /^Aut/i ) { return $period eq 'start' ? 6 : 12 }
        elsif ( $month =~ /^Win/i ) { return $period eq 'start' ? 9 : 12 }
        else {
            CUFTS::Exception::App->throw("Unable to find month match in fulltext date: $month");
        }
    }
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
        next if is_empty_string( $record->issn );

        my $result = new CUFTS::Result;
        $result->url( 'http://www.sciencedirect.com/science/journal/' . $record->issn );
        $result->record($record);

        push @results, $result;
    }

    return \@results;
}

1;
