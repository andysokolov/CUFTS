## CUFTS::Resources::Base::Catalog
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

package CUFTS::Resources::Base::Catalog;

use base qw(CUFTS::Resources);
use CUFTS::Exceptions qw(assert_ne);
use strict;


sub has_title_list {
	return 0;
}


sub can_getHoldings {
	my ($class, $request) = @_;

	if ( defined($request->genre) &&
	     ($request->genre eq 'journal' || $request->genre eq 'article') &&
	     (assert_ne($request->issn) || assert_ne($request->title) || assert_ne($request->eissn))) {
		return 1;
	} elsif ( ($request->genre eq 'book' || $request->genre eq 'bookitem') &&
	          (assert_ne($request->isbn) || assert_ne($request->title)) ) {
		return 1;
	}

	return 0;
}

sub search_getHoldings {
	my ($class, $schema, $resource, $site, $request) = @_;
	
	$class->can('build_linkHoldings') or
		CUFTS::Exception::App->throw("No build_linkHoldings method defined for class: $class");

	return $class->build_linkHoldings($resource, $site, $request);
}


1;
