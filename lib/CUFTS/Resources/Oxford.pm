## CUFTS::Resources::Oxford
##
## Copyright Todd Holbrook - Simon Fraser University (2003-12-24)
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

package CUFTS::Resources::Oxford;

use base qw(CUFTS::Resources::GenericJournalDOI);
use CUFTS::Exceptions;
use CUFTS::Util::Simple;
use URI::Escape;

use strict;

## title_list_fields - Controls what fields get displayed and loaded from
## title lists.

sub title_list_fields {
    return [
        qw(
            id
            title
            issn
            e_issn
            ft_start_date
            vol_ft_start
            iss_ft_start
            abbreviation
            journal_url
        )
    ];
}

# sub title_list_extra_requires {
#     require Text::CSV;
# }
# 
# sub title_list_split_row {
#     my ( $class, $row ) = @_;
# 
#     my $csv = Text::CSV->new();
#     $csv->parse($row)
#         or CUFTS::Exception::App->throw('Error parsing CSV line: ' . $csv->error_input() );
# 
#     my @fields = $csv->fields;
#     return \@fields;
# }

## title_list_field_map - Hash ref mapping fields from the raw title lists to
## internal field names

sub title_list_field_map {
    return {
        'Journal Title'        => 'title',
        'Print ISSN'           => 'issn',
        'Online ISSN'          => 'e_issn',
        'Short title'          => 'abbreviation',
        'Homepage URL'         => 'journal_url',
        'ft_end_date'          => 'ft_end_date',
    };
}


sub clean_data {
    my ( $class, $record ) = @_;

    if ( not_empty_string($record->{'___Prefix'}) && $record->{'___Prefix'} ne '-' ) {
        $record->{title} = $record->{'___Prefix'} . ' ' . $record->{title};
    }
    
    if ( not_empty_string($record->{issn}) && $record->{issn} eq '-' ) {
        delete $record->{issn};
    }

    if ( not_empty_string($record->{e_issn}) && $record->{e_issn} eq '-' ) {
        delete $record->{e_issn};
    }
    
    if ( not_empty_string($record->{'___PDF Starts'}) ) {
        
        if ( $record->{'___PDF Starts'} =~ / (\d+) : (\d*) /xsm ) {

            $record->{vol_ft_start} = $1;
            if ( not_empty_string($2) ) {
                $record->{iss_ft_start} = $2;
            }
            
        }
    
        if ( $record->{'___PDF Starts'} =~ / \( (\d{4}) \) /xsm ) {
            $record->{ft_start_date} = $1 . '-01-01';
        }
        
    }
 
    return $class->SUPER::clean_data($record);
}

1;
