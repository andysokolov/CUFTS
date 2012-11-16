## CJDB::DB::Links
##
## Copyright Todd Holbrook, Simon Fraser University (2003)
##
## This file is part of CJDB.
##
## CJDB is free software; you can redistribute it and/or modify it under
## the terms of the GNU General Public License as published by the Free
## Software Foundation; either version 2 of the License, or (at your option)
## any later version.
## 
## CJDB is distributed in the hope that it will be useful, but WITHOUT ANY
## WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
## FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
## details.
##
## You should have received a copy of the GNU General Public License along
## with CJDB; if not, write to the Free Software Foundation, Inc., 59
## Temple Place, Suite 330, Boston, MA 02111-1307 USA

package CJDB::DB::Links;

use strict;
use base 'CJDB::DB::DBI';
use CUFTS::DB::LocalResources;

__PACKAGE__->table('cjdb_links');
__PACKAGE__->columns(Primary => 'id');
__PACKAGE__->columns(All => qw(
	id

	journal
	
	resource
	local_journal
	
	print_coverage
	citation_coverage
	fulltext_coverage
	embargo
	current

	URL
	link_type
	rank
	
	site
));                                                                                                        
__PACKAGE__->columns(Essential => __PACKAGE__->columns);
__PACKAGE__->columns(TEMP => qw( journal_cjdb_note ));
__PACKAGE__->sequence('cjdb_links_id_seq');
__PACKAGE__->has_a('journal' => 'CJDB::DB::Journals');


sub local_resource {
	my ($self) = @_;
	
	my $site_id = $self->journal->site;
	my $resource_id = $self->resource;

	defined($resource_id) or
		return undef;

	my @local_resources = CUFTS::DB::LocalResources->search('site' => $site_id, 'id' => $resource_id);

	if (scalar(@local_resources) == 1) {
		return $local_resources[0];
	} else {
		return undef;
	}
}

__PACKAGE__->set_sql(display => qq{
    SELECT cjdb_links.*, COALESCE(local_journals.cjdb_note, journals.cjdb_note) AS journal_cjdb_note FROM cjdb_links
    LEFT OUTER JOIN local_journals 
    ON cjdb_links.local_journal = local_journals.id
    LEFT OUTER JOIN journals 
    ON local_journals.journal = journals.id
    WHERE cjdb_links.journal = ?;
});


1;
