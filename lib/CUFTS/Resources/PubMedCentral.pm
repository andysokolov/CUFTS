## CUFTS::Resources::PubMedCentral
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

package CUFTS::Resources::PubMedCentral;

use base qw(CUFTS::Resources::GenericJournalDOI CUFTS::Resources::Base::Journals);

use CUFTS::Exceptions;
use CUFTS::Util::Simple;
use HTML::Entities;
use URI::Escape qw(uri_escape);

use strict;

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

sub title_list_fields {
    return [
        qw(
            id
            title
            abbreviation
            issn
            e_issn
            ft_start_date
            vol_ft_start
            ft_end_date
            vol_ft_end
            iss_ft_end
            embargo_months
            publisher
            journal_url
        )
    ];
}

sub overridable_resource_details {
    return undef;
}

sub title_list_field_map {
    return {
        'Journal title'   => 'title',
        'NLM TA'          => 'abbreviation',
        'pISSN'           => 'issn',
        'eISSN'           => 'e_issn',
        'Publisher'       => 'publisher',
        'Free access'     => 'embargo_months',
        'Journal URL'     => 'journal_url',

    };
}

sub clean_data {
    my ( $class, $record ) = @_;

    $record->{title}                = HTML::Entities::decode_entities( $record->{title} );
    $record->{'___Earliest volume'} = HTML::Entities::decode_entities( $record->{'___Earliest volume'} );
    $record->{'___Latest issue'}    = HTML::Entities::decode_entities( $record->{'___Latest issue'} );

    if ( defined( $record->{embargo_months} ) ) {
        if ( $record->{embargo_months} =~ / (\d+) \s* months /xsmi ) {
            $record->{embargo_months} = $1;
        }
        else {
            delete $record->{embargo_months};
        }
    }

    if ( defined( $record->{'___Earliest volume'} ) ) {

        my ( $vol, $date ) = split /\s*;\s*/, $record->{'___Earliest volume'};
        defined($date)
            or $date = $record->{'___Earliest volume'};

        if ( $date =~ /(\d{4})/ ) {
            $record->{ft_start_date} = $1;
        }

        if ( defined($vol) && $vol =~ / v\. \s* (\d+) /xsm ) {
            $record->{vol_ft_start} = $1;
        }

    }

    if ( defined( $record->{'___Latest issue'} ) && !defined( $record->{embargo_months} ) ) {

        my $current_year = (localtime())[5] + 1900;

        my ( $vol, $date ) = split /\s*;\s*/, $record->{'___Latest issue'};
        defined($date)
            or $date = $record->{'___Latest issue'};

        if ( $date =~ /(\d{4}) \s* $/xsm && $1 ne $current_year ) {
            $record->{ft_end_date} = $1;

            if ( $date =~ /^ ([a-zA-Z]+) \s* (\d{1,2}) , \s* \d+ /xsm ) {
                $record->{ft_end_date} .= sprintf( "-%02d-%02d", get_month( $1, 'end' ), $2 );
            }
            elsif ( $date =~ /^ [a-zA-Z]{3} - ([a-zA-Z]{3}) /xsm ) {
                $record->{ft_end_date} .= sprintf( "-%02d", get_month( $1, 'end' ) );
            }
            elsif ( $date =~ /^ ([a-zA-Z]{3}) /xsm ) {
                $record->{ft_end_date} .= sprintf( "-%02d", get_month( $1, 'end' ) );
            }

            if ( defined($vol) && $vol =~ / v\. \s* (\d+) /xsm ) {
                $record->{vol_ft_end} = $1;
            }

            if ( defined($vol) && $vol =~ / \( (\d+) /xsm ) {
                $record->{iss_ft_end} = $1;
            }
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

sub can_getTOC {
    return 0;
}

1;
