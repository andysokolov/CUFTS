## CUFTS::Resources::Base::DOI
##
## Copyright Todd Holbrook - Simon Fraser University (2004)
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
## DOI is a helper base resource meant to supply extra routines
## to resources which list articles in doi.org.
##

package CUFTS::Resources::Base::DOI;

use CUFTS::Exceptions;
use CUFTS::Util::Simple;

use strict;

use URI::Escape;

sub services {
	return [ qw( fulltext journal database ) ];
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
		$url .= 'http://dx.doi.org/';
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
