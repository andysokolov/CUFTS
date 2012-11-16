## CUFTS::Resources::Gale10
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

package CUFTS::Resources::Gale10;

use base qw(CUFTS::Resources::Base::Journals);

use CUFTS::Exceptions;
use CUFTS::Util::Simple;
use URI::Escape;

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
            cit_start_date
            cit_end_date
            embargo_days
        )
    ];
}

## title_list_field_map - Hash ref mapping fields from the raw title lists to
## internal field names
##

sub title_list_field_map {
    return {
        'Journal Name'   => 'title',
        'ISSN'           => 'issn',
        'Embargo (Days)' => 'embargo_days',
    };
}

sub global_resource_details {
    my ($class) = @_;
    return [
        @{ $class->SUPER::global_resource_details },
        qw(
            resource_identifier
        )
    ];
}

sub local_resource_details {
    my ($class) = @_;
    return [
        @{ $class->SUPER::local_resource_details },
        qw(
            resource_identifier
            auth_name
        )
    ];
}

sub overridable_resource_details {
        my ($class) = @_;

        my $details = $class->SUPER::overridable_resource_details();
        push @$details, 'auth_name';

        return $details;
}


sub clean_data {
    my ( $class, $record ) = @_;

    # Skip " --- Formerly ... "
    
    if ( $record->{title} =~ / ^ \s* --- /xsm ) {
        return undef;
    }

    my ( $ft_start_date, $ft_end_date ) = ( '0', '0' );

    if ( defined( $record->{'___Index Start'} )
        && $record->{'___Index Start'} =~ /(\w{3})-(\d{2})/ )
    {
        my $temp_date = get_date( $1, $2 );
        $record->{cit_start_date} = substr( $temp_date, 0, 4 ) . '-' . substr( $temp_date, 4, 2 );
    }
    elsif ( defined( $record->{'___Index Start'} )
        && $record->{'___Index Start'} =~ /(\d{1,2})\/(\d{4})/ )
    {
        $record->{cit_start_date} = sprintf( "%04i-%02i", $2, $1);
    }

    if ( defined( $record->{'___Index End'} )
        && $record->{'___Index End'} =~ /(\w{3})-(\d{2})/ )
    {
        my $temp_date = get_date( $1, $2 );
        $record->{cit_end_date} = substr( $temp_date, 0, 4 ) . '-' . substr( $temp_date, 4, 2 );
    }
    elsif ( defined( $record->{'___Index End'} )
        && $record->{'___Index End'} =~ /(\d{1,2})\/(\d{4})/ )
    {   
        $record->{cit_end_date} = sprintf( "%04i-%02i", $2, $1);
    }

    # Gale can't seem to keep their columns consistent, so try an alternative

    if ( !exists($record->{'___Full-text Start'}) ) {
       $record->{'___Full-text Start'} = $record->{'___Full-Text Start'}
    }
    if ( !exists($record->{'___Full-text End'}) ) {
       $record->{'___Full-text End'} = $record->{'___Full-Text End'}
    }

    if ( defined( $record->{'___Full-text Start'} )
        && $record->{'___Full-text Start'} =~ /(\w{3})-(\d{2})/ )
    {
        $ft_start_date = get_date( $1, $2 );
    }
    elsif ( defined( $record->{'___Full-text Start'} )
        && $record->{'___Full-text Start'} =~ /(\d{1,2})\/(\d{4})/ )
    {
        $ft_start_date = sprintf( "%04i%02i", $2, $1);
    }

    if ( defined( $record->{'___Full-text End'} )
        && $record->{'___Full-text End'} =~ /(\w{3})-(\d{2})/ )
    {
        $ft_end_date = get_date( $1, $2 );
    }
    elsif ( defined( $record->{'___Full-text End'} )
        && $record->{'___Full-text End'} =~ /(\d{1,2})\/(\d{4})/ )
    {
        $ft_end_date = sprintf( "%04i%02i", $2, $1);
    }

    # Check the Image dates to see if they are better than the fulltext ones

    if ( defined( $record->{'___Image Start'} )
        && $record->{'___Image Start'} =~ /(\w{3})-(\d{2})/ )
    {
        my $temp_date = get_date( $1, $2 );
        if ( int($temp_date) < int($ft_start_date) ) {
            $ft_start_date = $temp_date;
        }
    }
    elsif ( defined( $record->{'___Image Start'} )
        && $record->{'___Image Start'} =~ /(\d{1,2})\/(\d{4})/ )
    {
	my $temp_date = sprintf( "%04i%02i", $2, $1);
	if ( int($temp_date) < int($ft_start_date) ) {
            $ft_start_date = $temp_date;
        }
    }

    if ( defined( $record->{'___Image End'} )
        && $record->{'___Image Start'} =~ /(\w{3})-(\d{2})/ )
    {
        my $temp_date = get_date( $1, $2 );
        if ( int($temp_date) > int($ft_end_date) ) {
            $ft_end_date = $temp_date;
        }
    }
    elsif ( defined( $record->{'___Image End'} )
        && $record->{'___Image End'} =~ /(\d{1,2})\/(\d{4})/ )
    {
        my $temp_date = sprintf( "%04i%02i", $2, $1);
        if ( int($temp_date) < int($ft_end_date) ) {
            $ft_end_date = $temp_date;
        }
    }

    if ( defined($ft_start_date) && $ft_start_date ne '0' ) {
        $record->{ft_start_date} = substr( $ft_start_date, 0, 4 ) . '-' . substr( $ft_start_date, 4, 2 );
    }
    if ( defined($ft_end_date) && $ft_end_date ne '0' ) {
        $record->{ft_end_date} = substr( $ft_end_date, 0, 4 ) . '-' . substr( $ft_end_date, 4, 2 );
    }

    $record->{title} =~ s/\s*\(.+?\)\s*$//g;

    return $class->SUPER::clean_data($record);

    sub get_date {
        my ( $month, $year ) = @_;

        if    ( $month =~ /^Jan/i ) { $month = 1 }
        elsif ( $month =~ /^Feb/i ) { $month = 2 }
        elsif ( $month =~ /^Mar/i ) { $month = 3 }
        elsif ( $month =~ /^Apr/i ) { $month = 4 }
        elsif ( $month =~ /^May/i ) { $month = 5 }
        elsif ( $month =~ /^Jun/i ) { $month = 6 }
        elsif ( $month =~ /^Jul/i ) { $month = 7 }
        elsif ( $month =~ /^Aug/i ) { $month = 8 }
        elsif ( $month =~ /^Sep/i ) { $month = 9 }
        elsif ( $month =~ /^Oct/i ) { $month = 10 }
        elsif ( $month =~ /^Nov/i ) { $month = 11 }
        elsif ( $month =~ /^Dec/i ) { $month = 12 }
        else {
            CUFTS::Exception::App->throw(
                "Unable to find month match in fulltext date: $month");
        }

        if ( int($year) > 20 ) {
            $year = "19$year";
        }
        else {
            $year = "20$year";
        }

        return sprintf( "%04i%02i", $year, $month );
    }
}


## resource_details_help - A hash ref containing the hoverover help for each of the
## local resource details
##

sub resource_details_help {
    my ($class) = @_;

    my $help_hash = $class->SUPER::resource_details_help;
    $help_hash->{'resource_identifier'} = 'Unique code defined by Gale for each database or resource.';
    $help_hash->{'auth_name'}           = 'Location ID assigned by Gale. Used in construction of an OpenURL.';
    return $help_hash;
}

## -------------------------------------------------------------------------------------------


sub build_linkJournal {
    my ( $class, $records, $resource, $site, $request ) = @_;

    defined($records) && scalar(@$records) > 0
        or return [];
    defined($resource)
        or CUFTS::Exception::App->throw('No resource defined in build_linkJournal');
    defined($site)
        or CUFTS::Exception::App->throw('No site defined in build_linkJournal');
    defined($request)
        or CUFTS::Exception::App->throw('No request defined in build_linkJournal');

    my $resource_identifier = $resource->resource_identifier;
    my $auth_name = $resource->auth_name;

    if ( !defined( $resource_identifier ) ) {
        warn('No resource_identifier defined for Gale10 resource: ' . $resource->name);
        return undef;
    }

    if ( !defined( $auth_name ) ) {
        warn('No auth_name defined for Gale10 resource: ' . $resource->name);
        return undef;
    }

    my @results;
    foreach my $record (@$records) {

        my $url = _build_base_url( $auth_name, $resource_identifier );

        if ( not_empty_string($record->issn) ) {
            my $issn = $record->issn;
            substr( $issn, 4, 0 ) = '-';
            $url .= "&rft.issn=${issn}";
        }
        else {
            my $escaped_title = uri_escape($record->title);
            $url .= "&rft.title=${escaped_title}";
            $url .= "&rft.jtitle=${escaped_title}";
        }

        my $result = new CUFTS::Result($url);
        $result->record($record);
        push @results, $result;
    }

    return \@results;
}


sub can_getTOC {
    my ( $class, $request ) = @_;

    return 0
        if is_empty_string( $request->volume ) && is_empty_string( $request->issue );

    return $class->SUPER::can_getFulltext($request);
}


sub build_linkTOC {
    my ( $class, $records, $resource, $site, $request ) = @_;

    defined($records) && scalar(@$records) > 0
        or return [];
    defined($resource)
        or CUFTS::Exception::App->throw('No resource defined in build_linkTOC');
    defined($site)
        or CUFTS::Exception::App->throw('No site defined in build_linkTOC');
    defined($request)
        or CUFTS::Exception::App->throw('No request defined in build_linkTOC');

    my $resource_identifier = $resource->resource_identifier;
    my $auth_name = $resource->auth_name;

    if ( !defined( $resource_identifier ) ) {
        warn('No resource_identifier defined for Gale10 resource: ' . $resource->name);
        return undef;
    }

    if ( !defined( $auth_name ) ) {
        warn('No auth_name defined for Gale10 resource: ' . $resource->name);
        return undef;
    }

    my @results;
    foreach my $record (@$records) {

        my $url = _build_base_url( $auth_name, $resource_identifier );

        if ( not_empty_string($record->issn) ) {
            my $issn = $record->issn;
            substr( $issn, 4, 0 ) = '-';
            $url .= "&rft.issn=${issn}";
        }
        else {
            my $escaped_title = uri_escape($record->title);
            $url .= "&rft.title=${escaped_title}";
            $url .= "&rft.jtitle=${escaped_title}";
        }

        if ( not_empty_string($request->volume) ) {
            $url .= '&rft.volume=' . $request->volume;
        }
    
        if ( not_empty_string($request->issue) ) {
            $url .= '&rft.issue=' . $request->issue;
        }

        # if ( not_empty_string($request->date) ) {
        #     $url .= '&rft.date=' . $request->date;
        # }

        my $result = new CUFTS::Result($url);
        $result->record($record);
        push @results, $result;
    }

    return \@results;
}

sub can_getFulltext {
    my ( $class, $request ) = @_;

    return 0
        if is_empty_string( $request->volume ) && is_empty_string( $request->issue );

    return 0
        if is_empty_string( $request->spage );

    return $class->SUPER::can_getFulltext($request);
}

# Creates an OpenURL 1.0 request for gale.

sub build_linkFulltext {
    my ( $class, $records, $resource, $site, $request ) = @_;

    defined($records) && scalar(@$records) > 0
        or return [];
    defined($resource)
        or CUFTS::Exception::App->throw('No resource defined in build_linkFulltext');
    defined($site)
        or CUFTS::Exception::App->throw('No site defined in build_linkFulltext');
    defined($request)
        or CUFTS::Exception::App->throw('No request defined in build_linkFulltext');

    my $resource_identifier = $resource->resource_identifier;
    my $auth_name = $resource->auth_name;

    if ( !defined( $resource_identifier ) ) {
        warn('No resource_identifier defined for Gale10 resource: ' . $resource->name);
        return undef;
    }

    if ( !defined( $auth_name ) ) {
        warn('No auth_name defined for Gale10 resource: ' . $resource->name);
        return undef;
    }

    my @results;
    foreach my $record (@$records) {

        my $url = _build_base_url( $auth_name, $resource_identifier );

        if ( not_empty_string($record->issn) ) {
            my $issn = $record->issn;
            substr( $issn, 4, 0 ) = '-';
            $url .= "&rft.issn=${issn}";
        }
        else {
            my $escaped_title = uri_escape($record->title);
            $url .= "&rft.title=${escaped_title}";
            $url .= "&rft.jtitle=${escaped_title}";
        }

        if ( not_empty_string($request->volume) ) {
            $url .= '&rft.volume=' . $request->volume;
        }
    
        if ( not_empty_string($request->issue) ) {
            $url .= '&rft.issue=' . $request->issue;
        }

        if ( not_empty_string($request->spage) ) {
            $url .= '&rft.spage=' . $request->spage;
        }

        # if ( not_empty_string($request->date) ) {
        #     $url .= '&rft.date=' . $request->date;
        # }

        my $result = new CUFTS::Result($url);
        $result->record($record);
        push @results, $result;
    }

    return \@results;
}


sub _build_base_url {
    my ( $auth_name, $resource_identifier ) = @_;
    
    return "http://find.galegroup.com/openurl/openurl?url_ver=Z39.88-2004&url_ctx_fmt=info%3Aofi%2Ffmt%3Akev%3Amtx%3Actx"
            . "&ctx_enc=info%3Aofi%3Aenc%3AUTF-8&rft_val_fmt=info%3Aofi%2Ffmt%3Akev%3Amtx%3Ajournal"
            . "&req_dat=info%3Asid%2Fgale%3Augnid%3A${auth_name}"
            . "&res_id=info%3Asid%2Fgale%3A${resource_identifier}";
}



1;
