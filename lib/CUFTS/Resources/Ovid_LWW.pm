## CUFTS::Resources::Ovid_LWW
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

package CUFTS::Resources::Ovid_LWW;

use base qw(CUFTS::Resources::OvidLinking);

use CUFTS::Exceptions;
use CUFTS::Util::Simple;

use strict;

sub title_list_field_map {
    return {
        'Journal Title'  => 'title',
        'ISSN'           => 'issn',
        'Jumpstart URL'  => 'journal_url',
    };
}

sub clean_data {
    my ( $class, $record ) = @_;

    $record->{title} =~ trim_string( $record->{title}, '"' );

    # Remove "®" character from title ends
    $record->{title} =~ s/\xAE$//xsm;

    # January-2001
    if ( $record->{'___Start Date'} =~ /^ ([a-z]{3,})-(\d{4}) /xsmi ) {
        $record->{ft_start_date} = format_date( $2, $1, undef, 'start' );
    }
    # January/February-2003
    elsif ( $record->{'___Start Date'} =~ /^ ([a-z]{3,}) \/ \w+ - (\d{4})/xsmi ) {
        $record->{ft_start_date} = format_date( $2, $1, undef, 'start' );
    }


    # January-2001
    if ( $record->{'___End Date'} =~ /^ ([a-z]{3,})-(\d{4}) /xsmi ) {
        $record->{ft_end_date} = format_date( $2, $1, undef, 'end' );
    }
    # January/February-2003
    elsif ( $record->{'___End Date'} =~ /^ \w+ \/ ([a-z]{3,}) - (\d{4})/xsmi ) {
        $record->{ft_end_date} = format_date( $2, $1, undef, 'end' );
    }


    if ( $record->{'___Start Vol(Issue)'} =~ / (\d+) (?: \( (\d*) \) )? /xsm ) {
        $record->{vol_ft_start} = $1;
        if ($2) {
            $record->{iss_ft_start} = $2;
        }
    }

    if ( $record->{'___End Vol(Issue)'} =~ / (\d+) (?: \( (\d*) \) )? /xsm ) {
        $record->{vol_ft_end} = $1;
        if ($2) {
            $record->{iss_ft_end} = $2;
        }
    }


    my @errors;

    # Skip records with no titles, they're not very useful

    if ( is_empty_string( $record->{title} ) ) {
        push @errors, 'Title is empty, skipping record';
    }

    push @errors, @{ $class->SUPER::clean_data($record) };

    return \@errors;



}

sub format_date {
    my ( $year, $month, $day, $period ) = @_;

    my $date;

    $year = format_year( $year, $period );
    defined($year) or return undef;
    $date = $year;

    $month = format_month( $month, $period );
    if ( defined($month) ) {
        $date .= sprintf( "-%02i", $month );
    }

    return $date;
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

    $month =~ /^\d+$/
        and return $month;

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

sub get_first {
    $_[0] =~ s/\-.*//;
    return $_[0];
}

1;
