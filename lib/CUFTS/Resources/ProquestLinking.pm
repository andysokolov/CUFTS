## CUFTS::Resources::ProquestLinking
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

package CUFTS::Resources::ProquestLinking;

use base qw(CUFTS::Resources::Base::Journals);

use CUFTS::Exceptions;
use CUFTS::Util::Simple;

use URI::Escape qw(uri_escape);

use strict;

sub services {
    return [ qw( fulltext journal database ) ];
}

sub local_resource_details {
    my ($class) = @_;
    return [
        @{ $class->SUPER::local_resource_details },
        qw(
            auth_name
        )
    ];
}

my $base_url = 'http://openurl.proquest.com/in?';

sub can_getFulltext {
    my ( $class, $request ) = @_;

    return 0 if is_empty_string( $request->spage );
    return $class->SUPER::can_getFulltext($request);
}

sub can_getTOC {
    my ( $class, $request ) = @_;

    return 0 if is_empty_string( $request->volume );
    return $class->SUPER::can_getTOC($request);
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

        my %params = ( 'service' => 'pq' );

        if ( not_empty_string( $record->issn ) ) {
            $params{issn} = $record->issn;
        }
        else {
            $params{title} = uri_escape( $record->title );
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


        my $url = $base_url;
        # Anything in the auth_name field at this point means use the new linking style
        if ( not_empty_string( $resource->auth_name ) ) {
            $url = 'http://gateway.proquest.com/openurl?ctx_ver=Z39.88-2004&res_id=xri:pqm&rft_val_fmt=ori:/fmt:kev:mtx:article&genre=article&';
            delete $params{service};
        }

        $url .= join '&', map { $_ . '=' . $params{$_} } keys %params;

        my $result = new CUFTS::Result($url);
        $result->record($record);

        push @results, $result;
    }

    return \@results;
}

sub build_linkTOC {
    my ( $class, $schema, $records, $resource, $site, $request ) = @_;

    defined($records) && scalar(@$records) > 0
        or return [];
    defined($resource)
        or CUFTS::Exception::App->throw('No resource defined in build_linkTOC');
    defined($site)
        or CUFTS::Exception::App->throw('No site defined in build_linkTOC');
    defined($request)
        or CUFTS::Exception::App->throw('No request defined in build_linkTOC');

    my @results;

    foreach my $record (@$records) {

        my %params = ( 'service' => 'pq' );

        if ( not_empty_string( $record->issn ) ) {
            $params{issn} = $record->issn;
        }
        else {
            $params{title} = uri_escape( $record->title );
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

        if ( !exists( $params{volume} ) && !exists( $params{issue} ) ) {
            if ( not_empty_string( $request->day) ) {
                $params{date} = $request->date;
            }
            elsif ( not_empty_string( $request->year ) ) {
                $params{date} = $request->year;
            }
        }

        if ( not_empty_string( $request->atitle ) ) {
            $params{atitle} = uri_escape( $request->atitle );
        }

        my $url = $base_url;
        $url .= join '&', map { $_ . '=' . $params{$_} } keys %params;

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

        # Anything in the auth_name field at this point means use the new linking style
        if ( not_empty_string( $resource->auth_name ) ) {
            if ( not_empty_string( $record->issn ) ) {
                $url = 'http://gateway.proquest.com/openurl?ctx_ver=Z39.88-2004&res_id=xri:pqm&rft_val_fmt=ori:/fmt:kev:mtx:journal&genre=journal&issn=' . $record->issn;
            }
            else {
                $url = 'http://gateway.proquest.com/openurl?ctx_ver=Z39.88-2004&res_id=xri:pqm&rft_val_fmt=ori:/fmt:kev:mtx:journal&genre=journal&title=' . uri_escape( $record->title );
            }
        }
        else {
            if ( not_empty_string( $record->db_identifier ) ) {
                $url = 'http://openurl.proquest.com/openurl?url_ver=Z39.88-2004&res_dat=xri:pqd&rft_val_fmt=info:ofi/fmt:kev:mtx:journal&genre=issue&rft_dat=xri:pqd:PMID=';
                $url .= $record->db_identifier;
            }
            elsif ( not_empty_string( $record->issn ) ) {
                $url = 'http://gateway.proquest.com/openurl?ctx_ver=Z39.88-2003&res_id=xri:pqd&rft_val_fmt=ori:fmt:kev:mtx:journal&svc_id=xri:pqil:context=title&issn=';
                $url .= $record->issn;
            }
            else {
                $url = 'http://gateway.proquest.com/openurl?ctx_ver=Z39.88-2003&res_id=xri:pqd&rft_val_fmt=ori:fmt:kev:mtx:journal&svc_id=xri:pqil:context=title&title=';
                $url .= uri_escape( $record->title );
            }
        }

        my $result = new CUFTS::Result($url);
        $result->record($record);

        push @results, $result;
    }

    return \@results;
}

1;
