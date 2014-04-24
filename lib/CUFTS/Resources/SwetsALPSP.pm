## CUFTS::Resources::SwetsALPSP
##
## Copyright Todd Holbrook - Simon Fraser University (2003-11-05)
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


##
## NOTE: Uses the Swets resource for linking code, but overrides the title loading code.
##

package CUFTS::Resources::SwetsALPSP;

use base qw(CUFTS::Resources::Swets);

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
            e_issn
            ft_start_date
            vol_ft_start
            iss_ft_start
            journal_url
            publisher
        )
    ];
}

## title_list_field_map - Hash ref mapping fields from the raw title lists to
## internal field names
##

sub title_list_field_map {

    return {
        'TitleName'             => 'title',
        'ISSN-paper'            => 'issn',
        'ISSN-electronic'       => 'e_issn',
        # 'MML'                   => 'journal_url',
        'Title Publisher'       => 'publisher',
    };
}

# Override Swets special row parsing (CSV) to use default tab delimited parser

sub title_list_extra_requires {}

sub title_list_split_row {
    my ( $class, $row ) = @_;
    return CUFTS::Resources::Base::Journals->title_list_split_row( $row );
}



sub clean_data {
    my ( $class, $record ) = @_;

    # Get rid of quotes around titles and publishers with commas in them

    $record->{title}     = trim_string( $record->{title},     '"' );
    $record->{publisher} = trim_string( $record->{publisher}, '"' );

    my $start = $record->{'___Backfiles'};

    if ( $start =~ /^ \s* (\d{4}) /xsm ) {
        $record->{ft_start_date} = $1 . '-01-01';
    }

    if ( $start =~ / vol \.? \s* (\d+) /xsm ) {
        $record->{vol_ft_start} = $1;
    }

    if ( $start =~ / iss \.? \s* (\d+) /xsm ) {
        $record->{iss_ft_start} = $1;
    }

    if ( defined($record->{e_issn}) && defined($record->{issn}) && $record->{e_issn} eq $record->{issn} ) {
        delete $record->{e_issn};
    }

    return CUFTS::Resources::Base::Journals->clean_data($record);
}

1;

__DATA__

Example title list data (2008-08).  Note the quoted fields.


Title	ISSN-paper	ISSN-electronic	Backfiles	MML	Publisher
Abstract and Applied Analysis	1085-3375	1687-0409	1997 vol. 2 iss.1+2	http://www.swetswise.com/link/access_db?issn=1085-3375	Hindawi Publishing Co
Across Languages and Cultures	1585-1923	1588-2519	2000 vol. 1 iss.1	http://www.swetswise.com/link/access_db?issn=1585-1923	Akadémiai Kiadó Rt
Acta Agronomica Hungarica	0238-0161	1588-2527	1999 vol. 47 iss.1	http://www.swetswise.com/link/access_db?issn=0238-0161	Akadémiai Kiadó Rt
Acta Alimenjtaria	0139-3006	1588-2535	1999 vol. 28 iss.2	http://www.swetswise.com/link/access_db?issn=0139-3006	Akadémiai Kiadó Rt
Acta Antiqua Academiae Scientiarum Hungaricae	0044-5975	1588-2543	1999 vol. 39 iss.1	http://www.swetswise.com/link/access_db?issn=0044-5975	Akadémiai Kiadó Rt
Acta Archaeologica Academiae Scientiarum Hungaricae	0001-5210	1588-2551	2001 vol. 52 iss.4	http://www.swetswise.com/link/access_db?issn=0001-5210	Akadémiai Kiadó Rt
Acta Biologica Hungarica	0236-5383	1588-256X	2001 vol. 52 iss.1	http://www.swetswise.com/link/access_db?issn=0236-5383	Akadémiai Kiadó Rt
Acta Botanica Hungarica	0236-6495	1588-2578	2001 vol. 42 iss.1	http://www.swetswise.com/link/access_db?issn=0236-6495	Akadémiai Kiadó Rt
Acta Ethnographica Hungarica	1216-9803	1588-2586	2000 vol. 44 iss.1	http://www.swetswise.com/link/access_db?issn=1216-9803	Akadémiai Kiadó Rt
Ägypten und Levante	1015-5104	1813-5145	2003 vol. 12	http://www.swetswise.com/link/access_db?issn=1015-5104	Austrian Academy of Sciences Press
AI Communications	0921-7126	0921-7126	1997 vol. 10 iss.1	http://www.swetswise.com/link/access_db?issn=0921-7126	IOS Press
"Allergy, Asthma, and Clinical Immunology"	1710-1484	1710-1492	2004 vol. 1 iss.1	http://www.swetswise.com/link/access_db?issn=1710-1484	BC Decker
