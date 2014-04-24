## CUFTS::Resources::ElsevierEurope
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

package CUFTS::Resources::ElsevierEurope;

use base qw(CUFTS::Resources::GenericJournalDOI);

use CUFTS::Util::Simple;
use HTML::Entities;
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
            publisher
            current_months
	    journal_url
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
		'ISSN'                   => 'issn',
		'Publisher'              => 'publisher',
		'Coverage Begins Volume' => 'vol_ft_start',
		'Coverage Begins Issue'  => 'iss_ft_start',
		'Coverage Ends Volume'   => 'vol_ft_end',
		'Coverage Ends Issue'    => 'iss_ft_end',
		'Entitlement Begins Date'=> 'ft_start_date',
		'Entitlement Ends Date'  => 'ft_end_date',
		'Short Cut URL'          => 'journal_url',
    };
}

sub title_list_extra_requires {
    require CUFTS::Util::CSVParse;
}

sub title_list_split_row {
    my ( $class, $row ) = @_;

    $row =~ s/;+\s*$//;
    $row =~ s/"",""/","/g;
    $row =~ s/([^,])"",/$1",/g;
    $row =~ s/,""([^,])/,"$1/g;
    $row =~ s/"+\s*$/"/;
    $row =~ s/([^,])"([^,]*)"([^,])/$1'$2'$3/g;

    $row =~ s/",([^"])/","$1/g;
    $row =~ s/([^"]),"/$1","/g;

    $row =~ s/"?;"?/;/g;
    $row =~ s/^"?Subscribed,"/"Subscribed","/;

    $row =~ s/\s*"/"/g;
    $row =~ s/"\s*/"/g;
    $row =~ s/([^",])"([^",])/$1'$2/g;
    $row =~ s/"""/","/;
    $row =~ s/'\s*'//g;

    my $csv = CUFTS::Util::CSVParse->new();
    $csv->parse($row)
        or CUFTS::Exception::App->throw(
        'Error parsing CSV line: ' . $csv->error_input() );
    my @fields = $csv->fields;
    return \@fields;
}

sub clean_data {
    my ( $class, $record ) = @_;

    if ( $record->{ft_start_date} =~ /(\d+)?\s*(\w+)\s+(\d+)/xsm ) {
	my ( $day, $month, $year ) = ( $1, $2, $3 );
	$month = get_month( $month, 'start' );
	if (!$month){
	    delete $record->{ft_start_date};
	}elsif (!$day){
	    $record->{ft_start_date} = sprintf( "%04d-%02d-01", $year, $month );
	}else{
	    $record->{ft_start_date} = sprintf( "%04d-%02d-%02d", $year, $month, $day );
	}
    }
    elsif ( $record->{ft_start_date} =~ /(\d+)-(\w+)-(\d+)/xsm ) {
        my ( $day, $month, $year ) = ( $1, $2, $3 );
        $month = get_month( $month, 'start' );
        $record->{ft_start_date} = sprintf( "%04d-%02d-%02d", $year, $month, $day );
    }
    elsif ( $record->{ft_start_date} =~ /(\d{4})/xsm ) {
        $record->{ft_start_date} = $1;
    }
    else {
        delete $record->{ft_start_date};
    }

    if ( $record->{ft_end_date} =~ /(\d+)?\s*(\w+)\s+(\d+)/xsm ) {
        my ( $day, $month, $year ) = ( $1, $2, $3 );
	my $current_year = (localtime)[5] + 1900;
        if ( int($year) >= $current_year ) {
            delete $record->{iss_ft_end};
            delete $record->{vol_ft_end};
            delete $record->{ft_end_date};
        }
        else {
            $month = get_month( $month, 'end' );
	    if (!$day){
        	$record->{ft_end_date} = sprintf( "%04d-%02d", $year, $month );
	    }else{
		$record->{ft_end_date} = sprintf( "%04d-%02d-%02d", $year, $month, $day );
	    }
        }
    }
    elsif ( $record->{ft_end_date} =~ /(\d+)-(\w+)-(\d+)/xsm ) {
        my ( $day, $month, $year ) = ( $1, $2, $3 );
        # Remove end periods if the year matches the current year
        my $current_year = (localtime)[5] + 1900;
        if ( int($year) >= $current_year ) {
            delete $record->{iss_ft_end};
            delete $record->{vol_ft_end};
            delete $record->{ft_end_date};
        }
        else {
            $month = get_month( $month, 'end' );
            $record->{ft_end_date} = sprintf( "%04d-%02d-%02d", $year, $month, $day );
        }
    }
    elsif ( $record->{ft_end_date} =~ /(\d{4})/xsm ) {
	$record->{ft_end_date} = $1;
	my $current_year = (localtime)[5] + 1900;
        if ( int($1) >= $current_year ) {
            delete $record->{iss_ft_end};
            delete $record->{vol_ft_end};
            delete $record->{ft_end_date};
        }
    }
    else {
        delete $record->{ft_end_date};
    }


    if ( $record->{vol_ft_start} =~ /^ (\d+) - /xsm ) {
        $record->{vol_ft_start} = $1;
    }
    if ( $record->{iss_ft_start} =~ /^ (\d+) - /xsm ) {
        $record->{iss_ft_start} = $1;
    }
    if ( $record->{vol_ft_end} =~ / - (\d+) $/xsm ) {
        $record->{vol_ft_end} = $1;
    }
    if ( $record->{iss_ft_end} =~ / - (\d+) $/xsm ) {
        $record->{iss_ft_end} = $1;
    }

    $record->{title} = HTML::Entities::decode_entities( $record->{title} );
    $record->{publisher} = HTML::Entities::decode_entities( $record->{publisher} );

    sub get_month {
        my ( $month, $period ) = @_;

        if    ( $month =~ /^January/i || $month =~ /^Jan/i ) { return 1 }
        elsif ( $month =~ /^February/i || $month =~ /^Feb/i ) { return 2 }
        elsif ( $month =~ /^March/i || $month =~ /^Mar/i ) { return 3 }
        elsif ( $month =~ /^April/i || $month =~ /^Apr/i ) { return 4 }
        elsif ( $month =~ /^May/i || $month =~ /^May/i ) { return 5 }
        elsif ( $month =~ /^June/i || $month =~ /^Jun/i ) { return 6 }
        elsif ( $month =~ /^July/i || $month =~ /^Jul/i ) { return 7 }
        elsif ( $month =~ /^August/i || $month =~ /^Aug/i ) { return 8 }
        elsif ( $month =~ /^September/i || $month =~ /^Sep/i ) { return 9 }
        elsif ( $month =~ /^October/i || $month =~ /^Oct/i ) { return 10 }
        elsif ( $month =~ /^November/i || $month =~ /^Nov/i ) { return 11 }
        elsif ( $month =~ /^December/i || $month =~ /^Dec/i ) { return 12 }
        elsif ( $month =~ /^Spr/i ) { return $period eq 'start' ? 1 : 6 }
        elsif ( $month =~ /^Sum/i ) { return $period eq 'start' ? 3 : 9 }
        elsif ( $month =~ /^Fal/i ) { return $period eq 'start' ? 6 : 12 }
        elsif ( $month =~ /^Aut/i ) { return $period eq 'start' ? 6 : 12 }
        elsif ( $month =~ /^Win/i ) { return $period eq 'start' ? 9 : 12 }
        else {
	    return 0;
#            CUFTS::Exception::App->throw("Unable to find month match in fulltext date: $month");
        }
    }

	$record->{title}     = utf8( $record->{title} )->latin1;
	$record->{publisher} = utf8( $record->{publisher} )->latin1;

    return $class->SUPER::clean_data($record);
}

1;
