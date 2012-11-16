## CUFTS::Resources::Base::DateTimeNatural
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

package CUFTS::Resources::Base::DateTimeNatural;

use DateTime::Format::Natural;
use CUFTS::Util::Simple;

use strict;

sub parse_date {
    my $class  = shift;
    my $start = shift;

    my $dt_parser = DateTime::Format::Natural->new();

    my $final;
    foreach my $date ( @_ ) {
        next if !defined($date);
        $date = trim_string( $date, '"' );
        $date = trim_string($date);
        next if is_empty_string($date);

        my $dt = $dt_parser->parse_datetime( $date );
        next if !$dt_parser->success;

        if ( !defined($final) ) {
            $final = $dt;
        }
        else {
            if ( $start && $dt < $final ) {
                $final = $dt;
            }
            elsif ( !$start && $dt > $final ) {
                $final = $dt;
            }
        }
    }
    
    return defined($final) ? $final->ymd : undef;
}

sub parse_start_date {
    my $class = shift;
    $class->parse_date( 1, @_ );
}

sub parse_end_date {
    my $class = shift;
    $class->parse_date( 0, @_ );
}

1;
