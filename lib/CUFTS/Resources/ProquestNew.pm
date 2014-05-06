## CUFTS::Resources::ProquestNew
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

package CUFTS::Resources::ProquestNew;

use base qw(CUFTS::Resources::Base::Journals);

use CUFTS::Exceptions;
use CUFTS::Util::Simple;

use URI::Escape qw(uri_escape);

use strict;

sub services {
    return [ qw( fulltext journal database ) ];
}

my $base_url = 'http://gateway.proquest.com/openurl?ctx_ver=Z39.88-2004&res_id=xri:pqm&rft_val_fmt=ori:/fmt:kev:mtx:journal';

sub global_resource_details {
    my ($class) = @_;
    return [
        @{ $class->SUPER::global_resource_details },
        qw(
            url_base
        )
    ];
}

sub title_list_fields {
    return [
        qw(
            id
            title
            issn
            ft_start_date
            ft_end_date
            embargo_days
            cit_start_date
            cit_end_date
            db_identifier
            publisher
            journal_url
            cjdb_note
        )
    ];
}

sub title_list_field_map {
    return {
        'Title'                         => 'title',
        'Publisher'                     => 'publisher',
        'ISSN'                          => 'issn',
        'Full Text (combined) First'    => 'ft_start_date',
        'Full Text (combined) Last'     => 'ft_end_date',
        'Embargo Days'                  => 'embargo_days',
        'Pub ID'                        => 'db_identifier',
        'Cit/Abs (combined) First'      => 'cit_start_date',
        'Cit/Abs (combined) Last'       => 'cit_end_date',
    }
}


sub title_list_skip_lines_count { return 2 }


sub clean_data {
    my ( $class, $record ) = @_;

    if ( not_empty_string($record->{ft_end_date}) && $record->{ft_end_date} =~ /current/i ) {
        delete $record->{ft_end_date};
    }
    if ( not_empty_string($record->{cit_end_date}) && $record->{cit_end_date} =~ /current/i ) {
        delete $record->{cit_end_date};
    }

    $record->{ft_start_date} = get_date( $record->{ft_start_date} );
    $record->{ft_end_date}   = get_date( $record->{ft_end_date} );

    $record->{cit_start_date} = get_date( $record->{cit_start_date} );
    $record->{cit_end_date}   = get_date( $record->{cit_end_date} );

    $record->{publisher} = trim_string($record->{publisher}, '"');

    return $class->SUPER::clean_data($record);

    sub get_date {
        my ($string) = @_;

        return undef if is_empty_string($string);

        my %dates;

        if ( $string =~ /(\d+)-([a-z]{3})-(\d{4})/ig ) {
            my ( $day, $month, $year ) = ( $1, $2, $3 );

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
                CUFTS::Exception::App->throw("Unable to find month match in fulltext date: $month");
            }

            return sprintf( "%04i-%02i-%02i", $year, $month, $day );
        }
    }

}

sub can_getFulltext {
    my ( $class, $request ) = @_;

    return 0 if is_empty_string( $request->spage );
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

        my $url = not_empty_string($resource->url_base) ? $resource->url_base : $base_url;
        $url .= '&genre=article';

        my %params;

        # if ( not_empty_string( $record->db_identifier ) ) {
        #     $url .= '&rft_dat=xri:pqd:PMID=' . $record->db_identifier;
        # }
        if ( not_empty_string( $record->issn ) ) {
            $url .= '&issn=' . $record->issn;
        }
        else {
            $url .= '&jtitle=' . uri_escape( $record->title );
        }

        ##
        ## Hack for Wall Street Journal - it doesn't have vol/iss indexed and
        ## does not return results if you include them in the search.
        ##

        if ( $record->issn ne '00999660' ) {
            if ( not_empty_string( $request->volume ) ) {
                $params{volume} = $request->volume;
            }
            if ( not_empty_string( $request->issue ) ) {
                $params{issue} = $request->issue;
            }
        }

        if ( !exists( $params{volume} ) && !exists( $params{issue} ) && is_empty_string( $request->atitle ) ) {
            if ( not_empty_string( $request->day) ) {
                $params{date} = $request->date;
            }
            elsif ( not_empty_string( $request->year ) ) {
                $params{date} = $request->year;
            }
        }

        $params{spage} = $request->spage;

        if ( not_empty_string( $request->atitle ) ) {
            my $atitle = $request->atitle;
            $atitle =~ s/\(.+?\)$//;
            $params{atitle} = uri_escape( $atitle );
        }

        $url .= '&' . join '&', map { $_ . '=' . $params{$_} } keys %params;

        my $result = new CUFTS::Result($url);
        $result->record($record);

        push @results, $result;
    }

    return \@results;
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
        my $url;
        if ( not_empty_string($record->journal_url) ) {
            $url = $record->journal_url;
        }
        else {
            $url = not_empty_string($resource->url_base) ? $resource->url_base : $base_url;
            $url .= '&svc_id=xri:pqil:context=title&genre=journal';
            if ( not_empty_string( $record->db_identifier ) ) {
                $url .= '&rft_dat=xri:pqd:PMID=' . $record->db_identifier;
            }
            elsif ( not_empty_string( $record->issn ) ) {
                $url .= '&issn=' . $record->issn;
            }
            else {
                $url .= '&jtitle=' . uri_escape( $record->title );
            }
        }


        my $result = new CUFTS::Result($url);
        $result->record($record);

        push @results, $result;
    }

    return \@results;
}


1;
