## CUFTS::Resources::ElsevierLocal
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

package CUFTS::Resources::ElsevierLocal;

use base qw(CUFTS::Resources::Elsevier);

use CUFTS::Exceptions;
use CUFTS::Util::Simple;

use strict;

sub title_list_field_map {
    return {
        'Publication Name'       => 'title',
        'Issn'                   => 'issn',
        'ISSN'                   => 'issn',
        'Short Cut URL'          => 'journal_url',
        'Home Page URL'          => 'journal_url',
        'Publisher'              => 'publisher',
        'Entitlement Begins Volume' => 'vol_ft_start',
        'Entitlement Begins Issue'  => 'iss_ft_start',
        'Entitlement Begins Date'   => 'ft_start_date',
        'Entitlement Ends Volume'   => 'vol_ft_end',
        'Entitlement Ends Issue'    => 'iss_ft_end',
        'Entitlement Ends Date'     => 'ft_end_date',
    };
}

sub title_list_skip_lines_count { return 0; }

sub skip_record {
    my ( $class, $record ) = @_;

    return 1 if $record->{'___Entitlement Status'} ne 'Subscribed';

    return 0 if $record->{'___Publication Type'} =~ /handbook/i;

    return 0;
}

## preprocess_file - Strip the BOM

sub preprocess_file {
    my ( $class, $IN ) = @_;

    use File::Temp;

    my ( $fh, $filename ) = File::Temp::tempfile();

    binmode($IN, 'UTF-8');

    my $first_row = <$IN>;
    $first_row =~ s/^[^"A-Za-z]+//;

    print $fh $first_row;
    while ( my $row = <$IN> ) {
        print $fh $row;
    }

    close *$IN;
    seek *$fh, 0, 0;

    return $fh;
}


1;
