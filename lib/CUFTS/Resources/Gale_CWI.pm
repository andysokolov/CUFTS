## CUFTS::Resources::Gale_CWI
##
## Copyright Michelle Gauthier - Simon Fraser University (2003)
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

package CUFTS::Resources::Gale_CWI;

use base qw(CUFTS::Resources::GenericJournal);

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
            ft_end_date
        )
    ];
}

## title_list_field_map - Hash ref mapping fields from the raw title lists to
## internal field names
##

sub title_list_field_map {
    return {
        'Title'       => 'title',
        'ISSN'        => 'issn',
        'First Issue' => 'ft_start_date',
        'Last Issue'  => 'ft_end_date',
    };
}

sub clean_data {
    my ( $class, $record ) = @_;

    $record->{'___FullText'} eq 'Yes'
        or return ['Fulltext not available for title'];

    $record->{'___Type'} eq 'Journal' || $record->{'___Type'} eq 'Newsletter'
        or return ['Publication type not suitable for loading'];

    if (   substr( $record->{'ft_start_date'}, 4, 2 ) eq '00'
        || substr( $record->{'ft_start_date'}, 4, 2 ) eq 'No' )
    {
        $record->{'ft_start_date'} = substr( $record->{'ft_start_date'}, 0, 4 );
    }
    elsif (substr( $record->{'ft_start_date'}, 6, 2 ) eq '00'
        || substr( $record->{'ft_start_date'}, 6, 2 ) eq 'No' )
    {
        $record->{'ft_start_date'} = substr( $record->{'ft_start_date'}, 0, 6 );
        substr( $record->{'ft_start_date'}, 4, 0 ) = '-';
    }
    else {
        substr( $record->{'ft_start_date'}, 4, 0 ) = '-';
        substr( $record->{'ft_start_date'}, 7, 0 ) = '-';
    }

    if (   substr( $record->{'ft_end_date'}, 4, 2 ) eq '00'
        || substr( $record->{'ft_end_date'}, 4, 2 ) eq 'No' )
    {
        $record->{'ft_end_date'} = substr( $record->{'ft_end_date'}, 0, 4 );
    }
    elsif (substr( $record->{'ft_end_date'}, 6, 2 ) eq '00'
        || substr( $record->{'ft_end_date'}, 6, 2 ) eq 'No' )
    {
        $record->{'ft_end_date'} = substr( $record->{'ft_end_date'}, 0, 6 );
        substr( $record->{'ft_end_date'}, 4, 0 ) = '-';
    }
    else {
        substr( $record->{'ft_end_date'}, 4, 0 ) = '-';
        substr( $record->{'ft_end_date'}, 7, 0 ) = '-';
    }

    $record->{'title'} =~ s/\s*\(.+?\)\s*$//g;

    return $class->SUPER::clean_data($record);
}

1;
