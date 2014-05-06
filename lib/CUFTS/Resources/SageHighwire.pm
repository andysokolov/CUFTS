## CUFTS::Resources::SageHighwire.pm
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

package CUFTS::Resources::SageHighwire;

use base qw(CUFTS::Resources::Base::Journals);

use CUFTS::Exceptions;
use CUFTS::Util::Simple;
use Date::Calc qw(Delta_Days Today);

use strict;

sub services {
    return [ qw( fulltext journal database ) ];
}

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
            ft_end_date
            vol_ft_start
            vol_ft_end
            iss_ft_start
            iss_ft_end
            journal_url
            db_identifier
        )
    ];
}

sub title_list_field_map {
    return {
        'Title'                 => 'title',
        'ISSN'                  => 'issn',
        'E-ISSN'                => 'e_issn',
        'EISSN'                 => 'e_issn',
        'URL'                   => 'journal_url',
        'First Volume'          => 'vol_ft_start',
        'FirstVolume'           => 'vol_ft_start',
        'First Issue Number'    => 'iss_ft_start',
        'FirstIssue'            => 'iss_ft_start',
        'Latest Volume'         => 'vol_ft_end',
        'LastVolume'            => 'vol_ft_end',
        'Latest Issue Number'   => 'iss_ft_end',
        'LastIssue'             => 'iss_ft_end',
        'SAGE Pub Code'         => 'db_identifier',
        'SAGEPubCode'           => 'db_identifier',
    }
}

sub clean_data {
    my ( $class, $record ) = @_;

    $record->{title} =~ s/ \xAE $//xsm;  # Remove trailing (r)

    $record->{ft_start_date} = sprintf( '%4i-%02i', ($record->{'___First Year'} || $record->{'___FirstYear'} ), ( $record->{'___First Month'} || $record->{'___FirstMonth'} ) );
    my $latest_year  = $record->{'___Latest Year'} || $record->{'___LastYear'};
    my $latest_month = $record->{'___Latest Month'} || $record->{'___LastMonth'};

    if ( not_empty_string($latest_year) && not_empty_string($latest_month) ) {
        $record->{ft_end_date}   = sprintf( '%4i-%02i', ( $record->{'___Latest Year'} || $record->{'___LastYear'} ), ( $record->{'___Latest Month'} || $record->{'___LastMonth'} )  );
    }

    my $errs = $class->SUPER::clean_data($record);

    if ( !scalar(@$errs) && not_empty_string($record->{ft_end_date}) ) {
        my ( $year, $month, $day ) = split( '-', $record->{ft_end_date} );
        if ( Delta_Days( $year, $month, $day, Today() ) < 366 ) {
            delete $record->{ft_end_date};
            delete $record->{vol_ft_end};
            delete $record->{iss_ft_end};
        }
    }

    return $errs;
}



## -------------------------------------------------------------------------------------------

## can_get* - Control whether or not an attempt to create a link is built.  This is run
## before the database is searched for possible title matches, so catching requests without
## enough data, etc. early (here) cuts down on database hits

sub can_getFulltext {
    my ( $class, $request ) = @_;

    return 0
        if     is_empty_string( $request->spage  )
            || is_empty_string( $request->volume )
            || is_empty_string( $request->issue  );

    return $class->SUPER::can_getFulltext($request);
}


sub build_linkFulltext {
    my ( $class, $schema, $records, $resource, $site, $request ) = @_;

    defined($records) && scalar(@$records) > 0
        or return [];
    defined($resource)
        or CUFTS::Exception::App->throw('No resource defined in build_linkFulltext');
    defined($site)
        or CUFTS::Exception::App->throw('No site defined in build_linkFulltext');
    defined($request)
        or CUFTS::Exception::App->throw('No request defined in build_linkFulltext');

    my @results;

    foreach my $record (@$records) {
        my $dir = 'reprint';
        my $url = $record->journal_url . '/cgi/' . $dir . '/';

        $url .= $request->volume . '/'
              . $request->issue  . '/'
              . $request->spage;

        my $result = new CUFTS::Result($url);
        $result->record($record);

        push @results, $result;
    }

    return \@results;
}


1;
