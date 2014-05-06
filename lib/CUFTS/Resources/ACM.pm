## CUFTS::Resources::Elsevier
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

package CUFTS::Resources::ACM;

use base qw(CUFTS::Resources::Base::DOI CUFTS::Resources::Base::Journals);

use CUFTS::Exceptions;
use CUFTS::Util::Simple;
use HTML::Entities;
use strict;

sub title_list_fields {
    return [ qw(
        id
        title
        abbreviation
        issn
        e_issn
        ft_start_date
        ft_end_date
        vol_ft_start
        vol_ft_end
        iss_ft_start
        iss_ft_end
        journal_url
    ) ];
}

sub resource_details_help {
    return {};
}

sub title_list_field_map {
    return {
    'TITLE'     => 'title',
    'ABBR'      => 'abbreviation',
    'ISSN'      => 'issn',
    'e-ISSN'    => 'e_issn',
    'PUBLICATION RANGE: START'  => 'ft_start_date',
    'PUBLICATION RANGE: LATEST PUBLISHED'   => 'ft_end_date',
    'SHORTCUT URL'  => 'journal_url'
    };
}

sub title_list_extra_requires {
    require CUFTS::Util::CSVParse;
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
    my ( $volume, $issue, $date );

    if ( not_empty_string( $record->{ft_start_date} ) ) {

        if ( $record->{ft_start_date} =~ /(Volume\s+\w+)?\s*(Issue\s+\w+)?\s*\((.+)\)/xsm ) {
            ( $volume, $issue, $date ) = ( $1, $2, $3 );
            $volume =~ s/Volume\s*// if not_empty_string($volume);
            $issue =~ s/Issue\s*// if not_empty_string($issue);

            if ( $date =~ /([a-zA-Z]+)\s*\d+,\s*(\d+)/ || $date =~ /([a-zA-Z]+)\s*(\d+)/ || $date =~ /([a-zA-Z]+).+(\d{4})/ || $date =~ /()((?:19|20)\d{2})/ ) {
                my ($month, $year) = ($1, $2);
                $month = get_month($month, 'start') || 1;
                $record->{ft_start_date} = sprintf("%04i-%02i-01", $year, $month);
                if (!$volume) {
                    delete $record->{vol_ft_start};
                }
                else {
                    $record->{vol_ft_start} = $volume;
                }
                if (!$issue) {
                    delete $record->{iss_ft_start};
                }
                else {
                    $record->{iss_ft_start} = $issue;
                }
            }
        }
    }

    if ( not_empty_string( $record->{ft_end_date} ) ) {
        if ( $record->{ft_end_date} =~ /(Volume\s*\w+)?\s*(Issue\s*\w+)?\s*\((.+)\)/xsm ) {
            ( $volume, $issue, $date ) = ( $1, $2, $3 );
            $volume =~ s/Volume\s*// if not_empty_string($volume);
            $issue =~ s/Issue\s*// if not_empty_string($issue);

            if ( $date =~ /(\w+)\s*((?:19|20)\d{2})/ || $date =~ /(\w+)\s*\d+,\s*((?:19|20)\d{2})/ || $date =~ /()((?:19|20)\d{2})/ ) {
                my ($month, $year) = ($1, $2);
                my $current_year = (localtime)[5] + 1900;
                if ( int($year) >= $current_year ) {
                    delete $record->{iss_ft_end};
                    delete $record->{vol_ft_end};
                    delete $record->{ft_end_date};
                }
                else {
                    $month = get_month($month, 'end') || 12;
                    $record->{ft_end_date} = sprintf("%04i-%02i-01", $year, $month);
                    if (!$volume) {
                        delete $record->{vol_ft_end};
                    }
                    else {
                        $record->{vol_ft_end} = $volume;
                    }
                    if (!$issue) {
                        delete $record->{iss_ft_end};
                    }
                    else {
                        $record->{iss_ft_end} = $issue;
                    }
                }
            }
        }
    }

    $record->{title} = HTML::Entities::decode_entities( $record->{title} );

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
            return undef;
        }
    }

    return $class->SUPER::clean_data($record);
}


1;
