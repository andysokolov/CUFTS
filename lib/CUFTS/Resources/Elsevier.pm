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

package CUFTS::Resources::Elsevier;

use base qw(CUFTS::Resources::Base::DOI CUFTS::Resources::Base::Journals);

use CUFTS::Exceptions;
use CUFTS::Util::Simple;
use HTML::Entities;
use Date::Calc qw(Delta_Days Today);
use Unicode::String qw(utf8);

use strict;

sub title_list_fields {
    return [
        qw(
            id
            title
            issn
            ft_start_date
            vol_ft_start
            iss_ft_start
            ft_end_date
            vol_ft_end
            iss_ft_end
            embargo_days
            embargo_months
            journal_url
            publisher
            current_months
        )
    ];
}

sub help_template {
    return 'help/Elsevier';
}

sub resource_details_help {
    return {};
}

sub title_list_field_map {
    return {
        'Publication Name'       => 'title',
        'Issn'                   => 'issn',
        'ISSN'                   => 'issn',
        'Short Cut URL'          => 'journal_url',
        'Home Page URL'          => 'journal_url',
        'Publisher'              => 'publisher',
        'Coverage Begins Volume' => 'vol_ft_start',
        'Coverage Begins Issue'  => 'iss_ft_start',
        'Coverage Begins Date'   => 'ft_start_date',
        'Coverage Ends Volume'   => 'vol_ft_end',
        'Coverage Ends Issue'    => 'iss_ft_end',
        'Coverage Ends Date'     => 'ft_end_date',
    };
}

sub title_list_extra_requires {
    require CUFTS::Util::CSVParse;
}

sub title_list_split_row {
    my ( $class, $row ) = @_;

    my $csv = CUFTS::Util::CSVParse->new();
    $csv->parse($row)
        or CUFTS::Exception::App->throw('Error parsing CSV line: ' . $csv->error_input() );

    my @fields = $csv->fields;
    return \@fields;
}

# sub title_list_skip_lines_count { return 3; }

sub skip_record {
    my ( $class, $record ) = @_;

    return 1 if not_empty_string( $record->{'___Entitlement Status'} )
             && $record->{'___Entitlement Status'} =~ /not\s+available/i;
    return 0;
}


sub clean_data {
    my ( $class, $record ) = @_;

    if ( not_empty_string( $record->{ft_start_date} ) ) {
        my ( $day, $month, $year );

        # 01-Sep-08
        if ( $record->{ft_start_date} =~ /(\d+)-(\w+)-(\d{2})/ ) {
            ( $day, $month, $year ) = ( $1, $2, $3 );
            $month = get_month($month, 'start');
        }
        # Jan-68 | January - February 1995 | Winter 1993
        elsif ( $record->{ft_start_date} =~ /^ ([A-Za-z]+) [^\d]* (\d{2,4}) $/xsm ) {
            ( $day, $month, $year ) = ( 1, $1, $2 );
            $month = get_month($month, 'start');
        }
        # 01/05/2005
        elsif ( $record->{ft_start_date} =~ /(\d+)\/(\d+)\/(\d{4})/ ) {
            ( $day, $month, $year ) = ( $1, $2, $3 );
        }
        # 1993
        elsif ( $record->{ft_start_date} =~ / (\d{4}) $/xsm ) {
            ( $day, $month, $year ) = ( 1, 1, $1 );
        }

        if ( defined($year) && defined($month) && defined($day) ) {
            if ( $year < 1000 ) {
                $year += $year > 19 ? 1900 : 2000;
            }
            $record->{ft_start_date} = sprintf("%04i-%02i-%02i", $year, $month, $day);
        }
        else {
            delete $record->{ft_start_date};
        }

    }

    if ( not_empty_string( $record->{ft_end_date} ) ) {
        my ( $day, $month, $year );

        # 31-Jan-90
        if ( $record->{ft_end_date} =~ /(\d+)-(\w+)-(\d{2})/ ) {
            ( $day, $month, $year ) = ( $1, $2, $3 );
            $month = get_month($month, 'end');
        }
        # May-90 | January-February 2000
        elsif ( $record->{ft_end_date} =~ / ([a-zA-Z]+) \s* -? \s* (\d{2,4}) $/xsm ) {
            ( $month, $year ) = ( $1, $2 );
            $month = get_month($month, 'end');
            $day = ( 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 )[$month-1];
        }
        # 01/05/2005
        elsif ( $record->{ft_end_date} =~ /(\d+)\/(\d+)\/(\d{4})/ ) {
            ( $day, $month, $year ) = ( $1, $2, $3 );
        }
        elsif ( $record->{ft_end_date} =~ / (\d{4}) $/xsm ) {
            ( $day, $month, $year ) = ( 31, 12, $1 );
        }

        if ( defined($year) && defined($month) && defined($day) ) {
            if ( $year < 1000 ) {
                $year += $year > 19 ? 1900 : 2000;
            }

            if ( Delta_Days( $year, $month, $day, Today() ) > 240 ) {
                $record->{ft_end_date} = sprintf("%04i-%02i-%02i", $year, $month, $day);
            }
            else {
                delete $record->{ft_end_date};
                delete $record->{vol_ft_end};
                delete $record->{iss_ft_end};
            }
        }
        else {
            delete $record->{ft_end_date};
        }

    }

    foreach my $field ( qw( vol_ft_start vol_ft_end iss_ft_start iss_ft_end ) ) {
        if ( not_empty_string($record->{$field}) && $record->{$field} =~ /\D/ ) {
            delete $record->{$field};
        }
    }

    $record->{title}     = HTML::Entities::decode_entities( $record->{title} );
    $record->{title}     = utf8( $record->{title} )->latin1;
    $record->{publisher} = utf8( $record->{publisher} )->latin1;

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
        elsif ( $month =~ /^Spring/i ) { return $period eq 'start' ? 1 : 6 }
        elsif ( $month =~ /^Summer/i ) { return $period eq 'start' ? 3 : 9 }
        elsif ( $month =~ /^Fall/i ) { return $period eq 'start' ? 6 : 12 }
        elsif ( $month =~ /^Autum/i ) { return $period eq 'start' ? 6 : 12 }
        elsif ( $month =~ /^Winter/i ) { return $period eq 'start' ? 9 : 12 }
        elsif ( $month =~ /^Spr/i ) { return $period eq 'start' ? 1 : 6 }
        elsif ( $month =~ /^Sum/i ) { return $period eq 'start' ? 3 : 9 }
        elsif ( $month =~ /^Fal/i ) { return $period eq 'start' ? 6 : 12 }
        elsif ( $month =~ /^Aut/i ) { return $period eq 'start' ? 6 : 12 }
        elsif ( $month =~ /^Win/i ) { return $period eq 'start' ? 9 : 12 }
        elsif ( $month =~ /^Quarter/i ) { return $period eq 'start' ? 1 : 12 }  # Ignore "xx Quarter"
        else {
            CUFTS::Exception::App->throw("Unable to find month match in fulltext date: $month");
        }
    }

    return $class->SUPER::clean_data($record);
}


sub build_linkJournal {
    my ( $class, $schema, $records, $resource, $site, $request ) = @_;

    defined($records) && scalar(@$records) > 0
        or return [];
    defined($resource)
        or CUFTS::Exception::App->throw('No resource defined in build_linkJournal');
    defined($site)
        or CUFTS::Exception::App->throw('No site defined in build_linkJournal');
    defined($request)
        or CUFTS::Exception::App->throw('No request defined in build_linkJournal');

    my @results;
    foreach my $record (@$records) {
        my $url = $record->journal_url;
        if ( is_empty_string($url) ) {
            next if is_empty_string( $record->issn );
            $url = 'http://www.sciencedirect.com/science/journal/' . $record->issn;
        }

        my $result = new CUFTS::Result;
        $result->url($url);
        $result->record($record);

        push @results, $result;
    }

    return \@results;
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
