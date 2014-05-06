## CUFTS::Resources::Blackwell
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

package CUFTS::Resources::Blackwell;

use base qw(CUFTS::Resources::Base::SFXLoader);

use CUFTS::Exceptions;
use CUFTS::Util::Simple;

use URI::Escape;

use strict;

sub services {
    return [ qw( journal database ) ];
}

## title_list_fields - Controls what fields get displayed and loaded from
## title lists.

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
        )
    ];
}

sub clean_data {
    my ( $self, $record ) = @_;
    $record = $self->SUPER::clean_data( $record );
    delete $record->{journal_url};
    return $record;
}

## global_resource_details - Controls which details are displayed on the global
## resource pages
##

sub global_resource_details {
    my ($class) = @_;
    return [
        @{ $class->SUPER::global_resource_details },
        qw(
            resource_identifier
            database_url
            url_base
        )
    ];
}

## local_resource_details - Controls which details are displayed on the local
## resource pages
##

sub local_resource_details {
    my ($class) = @_;
    return [
        @{ $class->SUPER::local_resource_details },
        qw(
            resource_identifier
            database_url
            url_base
            auth_name
            auth_passwd
        )
    ];
}

## overridable_resource_details - Controls which of the *global* resource details
## are displayed on the *local* resource pages to possibly be overridden
##

sub overridable_resource_details {
    my ($class) = @_;
    return [
        @{ $class->SUPER::overridable_resource_details },
        qw(
            resource_identifier
            database_url
            url_base
            auth_name
            auth_passwd
            )
    ];
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
        my $url = 'http://www3.interscience.wiley.com/cgi-bin/issn?DESCRIPTOR=PRINTISSN&VALUE=';
        my $issn = $record->{issn} || $record->{e_issn};
        substr( $issn, 4, 0 ) = '-';

        my $result = new CUFTS::Result( $url . $issn );
        $result->record($record);

        push @results, $result;
    }

    return \@results;
}

sub build_linkFulltext {
	my ($class, $schema, $records, $resource, $site, $request) = @_;

	defined($records) && scalar(@$records) > 0 or
		return [];
	defined($resource) or
		CUFTS::Exception::App->throw('No resource defined in build_linkFulltext');
	defined($site) or
		CUFTS::Exception::App->throw('No site defined in build_linkFulltext');
	defined($request) or
		CUFTS::Exception::App->throw('No request defined in build_linkFulltext');

	if ( not_empty_string($request->doi) ) {
		my $url;
		$url .= 'http://www.blackwell-synergy.com/doi/abs/';
		$url .= uri_escape($request->doi, "^A-Za-z0-9\-_.!~*'()\/");

		my $result = new CUFTS::Result($url);
		$result->record($records->[0]);

		return [$result];
	} else {
		return [];
	}
}

sub can_getFulltext {
	my ($class, $request) = @_;

	return 1 if not_empty_string($request->doi);
	return 0;
}


1;
