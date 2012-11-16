## CUFTS::Resources::Ovid
##
## Copyright Todd Holbrook - Simon Fraser University
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

## TODO: Reformat the regexes to be readable

package CUFTS::Resources::Ovid;

use base qw(CUFTS::Resources::OvidLinking);

use CUFTS::Exceptions;
use CUFTS::Util::Simple;
use Date::Calc qw(Delta_Days Today);

use strict;

sub title_list_field_map {
    return {
        'Journal Title'  => 'title',
        'ISSN'           => 'issn',
        'eISSN'          => 'issn',
        'Publisher'      => 'publisher',
        'Jumpstart'      => 'journal_url',
        'Beginning Volume' => 'vol_ft_start',
        'Beginning Issue'  => 'iss_ft_start',
        'Beginning Year Coverage'   => 'ft_start_date',
        'Latest Volume'   => 'vol_ft_end',
        'Latest Issue'    => 'iss_ft_end',
        'Ending Year Coverage'     => 'ft_end_date',
    };
}

sub clean_data {
    my ( $class, $record ) = @_;

    $record->{title}  = trim_string( $record->{title}, '"' );
    $record->{issn}   = trim_string( $record->{issn} );
    $record->{e_issn} = trim_string( $record->{e_issn} );

    # Remove "®" character from title ends
    $record->{title} =~ s/\xAE$//xsm;

    # Skip records with no titles, they're not very useful

    if ( is_empty_string( $record->{title} ) || $record->{issn} =~ m{N/A} || $record->{eissn} =~ /Catalog/ || $record->{'___Coverage'} =~ /Catalog/ ) {
        return ['Title is empty or issn/eissn indicate "catalog product", skipping record'];
    }

    # Strip (#12345) from publishers

    $record->{publisher} = trim_string( $record->{publisher}, '"');
    $record->{publisher} = trim_string( $record->{publisher} );
    $record->{publisher} =~ s/\s*\(#.+?\)$//;

    # Parse coverage

    if ( $record->{ft_start_date} =~ /(\w+)\s*(\d{1,2})(?:[-\/]\d{1,2})?,\s*(\d{4})/xsm ) {
        $record->{ft_start_date} = format_date($3, $1, 'start', $2);
    }elsif ( $record->{ft_start_date} =~ /([\w+\s*]+)\s*(\d{4})/xsm ) {
        $record->{ft_start_date} = format_date($2, trim_string($1), 'start');
    }

    if ( $record->{ft_end_date} =~ /(\w+)\s*(\d{1,2})(?:[-\/]\d{1,2})?,\s*(\d{4})/xsm ) {
        $record->{ft_end_date} = format_date($3, $1, 'end', $2);
    }elsif ( $record->{ft_end_date} =~ /([\w+\s*]+)\s*(\d{4})/xsm ) {
        $record->{ft_end_date} = format_date($2, trim_string($1), 'end');
    }

    # Remove end date, volume and issue if they looks recent

    if( $record->{ft_end_date} =~ /(\d{4})-(\d{2})[-(\d{2})]?/xsm ){
        if ( Delta_Days( $1, $2, 01, Today() ) < 240 ) {
            delete $record->{ft_end_date};
            delete $record->{vol_ft_end};
            delete $record->{iss_ft_end};
        }
    }

    # Ovid has some horrible data in their title list.. just skip the record if we don't seem to have a valid date.
    if ( not_empty_string($record->{ft_start_date}) && $record->{ft_start_date} !~ /^\d{4}/ ) {
        return [ 'Skipping record, could not parse a valid start date: ' . $record->{ft_start_date} ];
    }
    if ( not_empty_string($record->{ft_end_date}) && $record->{ft_end_date} !~ /^\d{4}/ ) {
        return [ 'Skipping record, could not parse a valid end date: ' . $record->{ft_end_date} ];
    }

    # Take out any vol/iss fields that don't look like plain numbers or are 0
    foreach my $field ( qw( iss_ft_start vol_ft_start iss_ft_end vol_ft_end ) ) {
        if ( $record->{$field} !~ /^\d+$/ || $record->{$field} == 0 ) {
            delete $record->{$field};
        }
    }

    return $class->SUPER::clean_data($record);
}


sub format_date {
    my ( $year, $month, $period, $day ) = @_;

    my $date;

    $year = format_year( $year, $period );
    defined($year) or return undef;

    $month = format_month( $month, $period );
    defined($month) or return undef;

    if (defined($day)){ return sprintf( "%04i-%02i-%02i", $year, $month, $day ); }
    else { return sprintf( "%04i-%02i", $year, $month ); }
}

sub format_year {
    my ( $year, $period ) = @_;
    length($year) == 4
        and return $year;

    if ( length($year) == 2 ) {
        if ( $year > 10 ) {
            return "19$year";
        }
        else {
            return "20$year";
        }
    }

    return undef;
}

sub format_month {
    my ( $month, $period ) = @_;

    defined($month) && $month ne ''
        or return undef;

    if ( $month =~ /^\d+$/ && $month <= 12 && $month >=1 ) { return $month; }
    if ( $month =~ /^\d+$/ && ($month < 1 || $month > 12) ) { return undef; }

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
    elsif ( $month =~ /^First Quarter/i ) { return $period eq 'start' ? 1 : 3 }
    elsif ( $month =~ /^Second Quarter/i ) { return $period eq 'start' ? 3 : 6 }
    elsif ( $month =~ /^Third Quarter/i ) { return $period eq 'start' ? 6 : 9 }
    elsif ( $month =~ /^Fourth Quarter/i ) { return $period eq 'start' ? 9 : 12 }
    elsif ( $month =~ /^Annual/i ) { return $period eq 'start' ? 1 : 12 }
    else {
        CUFTS::Exception::App->throw("Unable to find month match in fulltext date: $month");
    }

}

sub get_first {
    $_[0] =~ s/\-.*//;
    return $_[0];
}

1;
