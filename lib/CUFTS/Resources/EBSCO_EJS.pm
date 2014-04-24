## CUFTS::Resources::EBSCO_EJS
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

# PURPOSE:  for EBSCO hosted databases created by other sources

package CUFTS::Resources::EBSCO_EJS;

use base qw(CUFTS::Resources::Base::Journals);

use CUFTS::Exceptions qw(assert_ne);
use CUFTS::Util::Simple;
use URI::Escape;

use strict;

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
            db_identifier
            journal_url
        )
    ];
}

sub unique_title_list_identifier {
    return 'db_identifier';
}

sub title_list_field_map {
    return {
        'JournalID'         => 'db_identifier',
        'JournalName'       => 'title',
        'JournalPaperISSN'  => 'issn',
        'JournalOnlineISSN' => 'e_issn',
        'URL'               => 'journal_url',
    };
}

sub clean_data {
    my ( $class, $record ) = @_;

    defined( $record->{'issn'} )
        and $record->{'issn'} =~ s/[^xX0-9]//g;
    defined( $record->{'e_issn'} )
        and $record->{'e_issn'} =~ s/[^xX0-9]//g;

    my $start = $record->{'___EJS Coverage From'};
    my $end   = $record->{'___EJS Coverage To'};

    defined($start) && $start =~ m#n/a#
        and $start = undef;
    defined($end) && $end =~ m#n/a#
        and $end = undef;

    if ( defined($start) ) {
        $start =~ s/ \s* released \s* //xsmi;
        $start =~ s/ \s* quarter  \s* //xsmi;

        $start =~ s/ \(No\. \s* /(/xsmi;

        if ( $start =~ / volume \s+ -? ([0-9]+) /xsmi ) {
            $record->{vol_ft_start} = $1;
        }

        if ( $start =~ / numbers? \s+ -? ([0-9]+) /xsmi ) {
            $record->{iss_ft_start} = $1;
        }

        if (    $start =~ / \( \s* ([A-Za-z]+) \s+ (\d+) \s* ,? \s* (\d{4}) \s* \) /xsm ) {
            my $month = get_month( $1, 'start' );
            if ( defined($month) ) {
                $record->{ft_start_date} = sprintf( "%04i-%02i-%02i", $3, $month, $2 );
            }
            else {
                $record->{ft_start_date} = sprintf( "%04i", $3 );
            }
        }
        elsif ( $start =~ / \( \s* ([A-Za-z]+) [^A-Za-z]+ [A-Za-z]+ ,? \s* (\d{4}) \s* \) /xsm )
        {
            my $month = get_month( $1, 'start' );
            if ( defined($month) ) {
                $record->{ft_start_date} = sprintf( "%04i-%02i", $2, $month );
            }
            else {
                $record->{ft_start_date} = sprintf( "%04i", $2 );
            }
        }
        elsif ( $start =~ / \( \s* ([A-Za-z]+) \s* ,? \s* (\d{4}) \s* \) /xsm ) {
            my $month = get_month( $1, 'start' );
            if ( defined($month) ) {
                $record->{ft_start_date} = sprintf( "%04i-%02i", $2, $month );
            }
            else {
                $record->{ft_start_date} = sprintf( "%04i", $2 );
            }
        }
        elsif ( $start =~ / \( \s* (\d{4}) \s* \) /xsm ) {
            $record->{ft_start_date} = $1;
        }
    }

    if ( defined($end) ) {

        $end =~ s/ \s* released \s*//xsmi;
        $end =~ s/ \s* quarter  \s*//xsmi;

        $end =~ s/ \(No\. \s* /(/xsmi;

        if ( $end =~ / volume \s+ -? ([0-9]+) /xsmi ) {
            $record->{vol_ft_end} = $1;
        }

        if ( $end =~ / numbers \s+ [0-9]+ \s* [-\/] \s* ([0-9]+) /xsmi ) {
            $record->{iss_ft_end} = $1;
        }
        elsif ( $end =~ / number \s* -? \s* ([0-9]+) /xsmi ) {
            $record->{iss_ft_end} = $1;
        }

        if ( $end =~ / \( \s* ([A-Za-z]+) \s+ (\d+) \s* ,? \s* (\d{4}) \s* \) /xsm ) {
            my $month = get_month( $1, 'end' );
            if ( defined($month) ) {
                $record->{ft_end_date} = sprintf( "%04i-%02i-%02i", $3, $month, $2 );
            }
            else {
                $record->{ft_end_date} = sprintf( "%04i", $3 );
            }
        }
        elsif ( $end =~ / \( \s* [A-Za-z]+ \s* [^A-Za-z\s] \s* ([A-Za-z]+) \s* ,? \s* (\d{4}) \s* \)/xsm )
        {
            my $month = get_month( $1, 'end' );
            if ( defined($month) ) {
                $record->{ft_end_date} = sprintf( "%04i-%02i", $2, $month );
            }
            else {
                $record->{ft_end_date} = sprintf( "%04i", $2 );
            }
        }
        elsif ( $end =~ / \( \s* ([A-Za-z]+) \s* ,? \s* (\d{4}) \s* \)/xsm ) {
            my $month = get_month( $1, 'end' );
            if ( defined($month) ) {
                $record->{ft_end_date} = sprintf( "%04i-%02i", $2, $month );
            }
            else {
                $record->{ft_end_date} = sprintf( "%04i", $2 );
            }
        }
        elsif ( $end =~ / \( \s* (\d{4}) \s* \) /xsm ) {
            $record->{ft_end_date} = $1;
        }

        my $current_year = (localtime)[5] + 1900;
        if (  defined( $record->{ft_end_date} )
            && substr( $record->{ft_end_date}, 0, 4) eq $current_year )
        {
            delete $record->{ft_end_date};
            delete $record->{vol_ft_end};
            delete $record->{iss_ft_end};
        }
    }

    sub get_month {
        my ( $month, $period ) = @_;

        if    ( $month =~ /^Jan/i )    { return 1 }
        elsif ( $month =~ /^Feb/i )    { return 2 }
        elsif ( $month =~ /^Mar/i )    { return 3 }
        elsif ( $month =~ /^Apr/i )    { return 4 }
        elsif ( $month =~ /^May/i )    { return 5 }
        elsif ( $month =~ /^Jun/i )    { return 6 }
        elsif ( $month =~ /^Jul/i )    { return 7 }
        elsif ( $month =~ /^Aug/i )    { return 8 }
        elsif ( $month =~ /^Sep/i )    { return 9 }
        elsif ( $month =~ /^O[ck]t/i ) { return 10 }
        elsif ( $month =~ /^Nov/i )    { return 11 }
        elsif ( $month =~ /^De[cz]/i )    { return 12 }  # Don't ask me why they have a few "Dezember" typos in their list
        elsif ( $month =~ /^Spr/i )    { return $period eq 'start' ? 1 : 6 }
        elsif ( $month =~ /^Sum/i )    { return $period eq 'start' ? 3 : 9 }
        elsif ( $month =~ /^Fal/i )    { return $period eq 'start' ? 6 : 12 }
        elsif ( $month =~ /^Aut/i )    { return $period eq 'start' ? 6 : 12 }
        elsif ( $month =~ /^Win/i )    { return $period eq 'start' ? 9 : 12 }
        elsif ( $month =~ /^First/i )  { return $period eq 'start' ? 1 : 6 }
        elsif ( $month =~ /^Second/i ) { return $period eq 'start' ? 3 : 9 }
        elsif ( $month =~ /^Third/i )  { return $period eq 'start' ? 6 : 12 }
        elsif ( $month =~ /^Fourth/i ) { return $period eq 'start' ? 9 : 12 }
        else {
            warn("Unable to find month match in fulltext date: $month");
            return undef;
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
        next if is_empty_string( $record->db_identifier );

        my $result = new CUFTS::Result;
        $result->url("http://ejournals.ebsco.com/direct.asp?JournalID=" . $record->db_identifier);
        $result->record($record);

        push @results, $result;
    }

    return \@results;
}

sub build_linkDatabase {
    my ( $class, $schema, $records, $resource, $site, $request ) = @_;

    my $id = $resource->resource_identifier or return [];

    my @results;

    foreach my $record (@$records) {

        my $url = $resource->database_url || 'http://ejournals.ebsco.com';
        my $result = new CUFTS::Result($url);
        $result->record($record);

        push @results, $result;
    }

    return \@results;
}

1;
