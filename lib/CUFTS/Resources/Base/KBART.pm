## CUFTS::Resources::Base::KBART
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

package CUFTS::Resources::Base::KBART;

use strict;

use base qw(CUFTS::Resources::Base::Journals);

use CUFTS::Exceptions;
use CUFTS::Util::Simple;
use String::Util qw(hascontent);

sub title_list_field_map {
    return {
        'print_identifier'          => 'issn',
        'online_identifier'         => 'e_issn',
        'publication_title'         => 'title',
        'title_url'                 => 'journal_url',
        'publisher_name'            => 'publisher',
        'date_first_issue_online'   => 'ft_start_date',
        'date_last_issue_online'    => 'ft_end_date',
        'num_first_vol_online'      => 'vol_ft_start',
        'num_first_issue_online'    => 'iss_ft_start',
        'num_last_vol_online'       => 'vol_ft_end',
        'num_last_issue_online'     => 'iss_ft_end',
        'title_id'                  => 'db_identifier',
    };
}


sub clean_data {
    my ( $class, $record ) = @_;

    # if ( !hascontent($record->{title}) ) {
    #     # There's an issue with BOM before the publication_title... Might need to deal with Unicode encoding here, which
    #     # will probably fix it, but in the short term we'll cheat and grab the publication_title field regardless of any
    #     # unprintable characters
    #     foreach my $field ( keys %$record ) {
    #         if ( $field =~ /publication_title/ ) {
    #             $record->{title} = $record->{$field};
    #             last;
    #         }
    #     }
    # }

	# Skip records where the ISSN looks like it's actually an ISBN
	if ( (hascontent($record->{issn}) && $record->{issn} =~ /^[-\dxX]{10,20}$/) || (hascontent($record->{e_issn}) && $record->{e_issn} =~ /^[-\dxX]{10,20}$/)  ) {
		return ['Skipping record that appears to have an ISBN: ' . $record->{issn} . ', ' . $record->{e_issn} ];
	}

	# Convert KBART embargo shorthands to months and days
    my $embargo = $record->{___embargo_info};
    if ( hascontent($embargo) && $embargo =~ /^(\w)(\d+)(\w)$/ ) {
        my ( $type, $amount, $period ) = ( $1, $2, $3 );
        
        if ( $type eq 'P' ) {
            if ( $period eq 'Y' ) {
                $record->{embargo_months} = $amount * 12;
            }
            elsif ( $period eq 'M' ) {
                $record->{embargo_months} = $amount;
            }
            elsif ( $period eq 'D' ) {
                $record->{embargo_days} = $amount;
            }
            else {
                return [ "Unrecognized embargo period: $period" ];
            }
        }
        elsif ( $type eq 'R' ) {
            if ( $period eq 'Y' ) {
                $record->{current_years} = $amount;
            }
            elsif ( $period eq 'M' ) {
                $record->{current_months} = $amount;
            }
            elsif ( $period eq 'D' ) {
                $record->{current_months} = int($amount / 30);
            }
            else {
                return [ "Unrecognized embargo period: $period" ];
            }
        }
        else {
            return [ "Unrecognized embargo type: $type" ];
        }
        
    }
    

    return $class->SUPER::clean_data($record);
}


1;
