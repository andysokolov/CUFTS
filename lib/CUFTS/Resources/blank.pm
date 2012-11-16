## CUFTS::Resources::blank
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

package CUFTS::Resources::blank;

use base qw(CUFTS::Resources::Base::Journals);

use CUFTS::Exceptions;

use strict;

sub title_list_fields {
	return [qw(
		id
		title
		issn
		ft_start_date
		ft_end_date
		cit_start_date
		cit_end_date
		embargo_months
		embargo_days
	)];
}

sub global_resource_details {
	return [qw(
	)];
}

sub local_resource_details {
	return [qw(
	)];
}

sub title_list_field_map {
	return {
	};
}

sub clean_data {
	my ($class, $record) = @_;
	my @errors;

	my $errors = $class->SUPER::clean_data($record);
	push @errors, @$errors if defined($errors);

	return \@errors;
}

sub build_linkFulltext {
	return [];
}

sub build_linkJournal {
	return [];
}

sub build_linkDatabase {
	return [];
}

sub build_linkTOC {
	return [];
}

sub build_linkWebSearch {
	return [];
}

sub build_linkHoldings {
	return [];
}



1;