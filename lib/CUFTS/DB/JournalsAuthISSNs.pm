## CUFTS::DB::Journals
##
## Copyright Todd Holbrook, Simon Fraser University (2003)
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

package CUFTS::DB::JournalsAuthISSNs;

use strict;
use base 'CUFTS::DB::DBI';


__PACKAGE__->table('journals_auth_issns');
__PACKAGE__->columns(Primary => 'id');
__PACKAGE__->columns(All => qw(
	id

	journal_auth

	issn
	info
));                                                                                                        
__PACKAGE__->columns(Essential => __PACKAGE__->columns);

__PACKAGE__->sequence('journals_auth_issns_id_seq');

__PACKAGE__->has_a('journal_auth', 'CUFTS::DB::JournalsAuth');

sub normalize_column_values {
	my ($self, $values) = @_;
	
	# Check ISSN for dashes and strip them out
	
	if (exists($values->{'issn'}) && defined($values->{'issn'}) && $values->{'issn'} ne '') {
		$values->{'issn'} = uc($values->{'issn'});
		$values->{'issn'} =~ tr/0-9X//cd;
		$values->{'issn'} =~ /^\d{7}[\dX]$/ or
			$self->_croak('issn is not valid: ' . $values->{'issn'});
	}

	return 1;
}

sub issn_dash {
    my ($self) = @_;
    my $issn = $self->issn;
    substr($issn, 4, 0) = '-';
    return $issn;
}


1;
