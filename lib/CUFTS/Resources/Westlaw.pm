## CUFTS::Resources::Westlaw
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

package CUFTS::Resources::Westlaw;

use base qw(CUFTS::Resources::GenericJournal);

use CUFTS::Exceptions;
use String::Util qw(trim hascontent);

use strict;


sub local_resource_details {
	return [qw(
		auth_name
	)];
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

	if ( !hascontent($resource->auth_name) ) {
		warn('No auth_name set for Westlaw resource id: ' . $resource->id);
		return [];
	}

	my @results;

	foreach my $record (@$records) {
		next if !hascontent( $record->journal_url );

		my $result = new CUFTS::Result( $record->journal_url . $resource->auth_name );
		$result->record($record);

		push @results, $result;
	}

	return \@results;
}

1;
