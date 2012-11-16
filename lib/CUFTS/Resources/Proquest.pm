## CUFTS::Resources::Proquest
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

package CUFTS::Resources::Proquest;

use CUFTS::Resources::ProquestLinking;

use base qw(CUFTS::Resources::ProquestLinking);

use CUFTS::Exceptions;
use CUFTS::Util::Simple;

use URI::Escape qw(uri_escape);

use strict;

my $base_url = 'http://openurl.proquest.com/in?';

sub title_list_fields {
    return [
        qw(
            id
            title
            issn
            ft_start_date
            ft_end_date
            cit_start_date
            cit_end_date
            embargo_days
            db_identifier
            cjdb_note
        )
    ];
}

sub title_list_skip_lines_count { return 3 }

sub title_list_get_field_headings {
    my ( $class, $IN, $no_map ) = @_;
    my @headings;

    my $headings_array = $class->title_list_parse_row($IN);
    return undef if !defined($headings_array) || ref($headings_array) ne 'ARRAY';

    my @real_headings;
    foreach my $heading (@$headings_array) {
        if    ( $heading =~ /^Title/i )                { $heading = 'title'               }
        elsif ( $heading =~ /^ISSN/i )                 { $heading = 'issn'                }
        elsif ( $heading =~ /^Full\s+Text\s+First/i )  { $heading = 'ft_start_date'       }
        elsif ( $heading =~ /^Full\s+Text\s+Last/i )   { $heading = 'ft_end_date'         }
        elsif ( $heading =~ /^Page\s*Image\s+First/i ) { $heading = '___image_start_date' }
        elsif ( $heading =~ /^Page\s*Image\s+Last/i )  { $heading = '___image_end_date'   }
        elsif ( $heading =~ /^Citation\s+First/i )     { $heading = 'cit_start_date'      }
        elsif ( $heading =~ /^Citation\s+Last/i )      { $heading = 'cit_end_date'        }
        elsif ( $heading =~ /^Embargo\s+Days/i )       { $heading = 'embargo_days'        }
        elsif ( $heading =~ /PM-ID/i )                { $heading = 'db_identifier'       }
        else { $heading = "___$heading" }

        push @real_headings, $heading;
    }

    return \@real_headings;
}

sub clean_data {
    my ( $class, $record ) = @_;

    my @errors;

    defined( $record->{ft_start_date} )
        and $record->{ft_start_date} =~ s#(\d{2})/(\d{2})/(\d{4})#$3$1$2#;
    defined( $record->{ft_end_date} )
        and $record->{ft_end_date} =~ s#(\d{2})/(\d{2})/(\d{4})#$3$1$2#;

    if ( defined( $record->{'___image_start_date'} ) ) {
        $record->{'___image_start_date'} =~ s#(\d{2})/(\d{2})/(\d{4})#$3$1$2#;
        if ( !defined( $record->{ft_start_date} )
            || $record->{'___image_start_date'} < $record->{ft_start_date} )
        {
            $record->{'ft_start_date'} = $record->{'___image_start_date'};
        }
    }
    
    if ( defined( $record->{'___image_end_date'} ) ) {
        $record->{'___image_end_date'} =~ s#(\d{2})/(\d{2})/(\d{4})#$3$1$2#;
        if ( !defined( $record->{ft_end_date} ) ) {
            $record->{ft_end_date} = $record->{'___image_end_date'};
        }
        elsif (
            ( $record->{ft_end_date} !~ /current/i )
            && ( ( $record->{'___image_end_date'} =~ /current/i )
                || ( $record->{'___image_end_date'} > $record->{ft_end_date} ) )
            )
        {
            $record->{ft_end_date} = $record->{'___image_end_date'};
        }
    }

    defined( $record->{cit_start_date} )
        and $record->{cit_start_date} =~ s#(\d{2})/(\d{2})/(\d{4})#$3-$1-$2#;
    defined( $record->{cit_end_date} )
        and $record->{cit_end_date} =~ s#(\d{2})/(\d{2})/(\d{4})#$3-$1-$2#;

    if ( defined( $record->{embargo_days} ) ) {
        if ( $record->{embargo_days} =~ /ft=(\d+)/ ) {
            $record->{embargo_days} = $1;
        }
        elsif ( $record->{embargo_days} =~ /img=(\d+)/ ) {
            $record->{embargo_days} = $1;
        }
        elsif ( $record->{embargo_days} =~ /tg=(\d+)/ ) {
            $record->{embargo_days} = $1;
        }
        elsif ( $record->{embargo_days} =~ /\b(\d+)\b/ ) {
            $record->{embargo_days} = $1;
        }
        else {
            delete( $record->{embargo_days} );
        }
    }

    if ( defined( $record->{ft_end_date} ) && $record->{ft_end_date} =~ /current/i ) {
        delete( $record->{ft_end_date} );
    }
        
    if ( defined( $record->{cit_end_date} ) && $record->{cit_end_date} =~ /current/i ) {
        delete( $record->{cit_end_date} );
    }

    if ( defined( $record->{ft_start_date} ) ) {
        substr( $record->{ft_start_date}, 4, 0 ) = '-';
        substr( $record->{ft_start_date}, 7, 0 ) = '-';
    }

    if ( defined( $record->{ft_end_date} ) ) {
        substr( $record->{ft_end_date}, 4, 0 ) = '-';
        substr( $record->{ft_end_date}, 7, 0 ) = '-';
    }

#    $record->{title} =~ s/\s*\(.+?\)\s*$//g;

    push @errors, @{ $class->SUPER::clean_data($record) };

    return \@errors;
}

sub overridable_resource_details {
    return undef;
}

sub help_template {
    return 'help/Proquest';
}

sub resource_details_help {
    return {};
}

1;
