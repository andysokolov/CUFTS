## CJDB::DB::Associations
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

package CJDB::DB::Associations;

use strict;
use base 'CJDB::DB::DBI';
use CJDB::DB::Journals;

__PACKAGE__->table('cjdb_associations');
__PACKAGE__->columns( Primary => 'id' );
__PACKAGE__->columns(
    All => qw(
        id
        association
        search_association
    )
);
__PACKAGE__->columns( Essential => __PACKAGE__->columns );
__PACKAGE__->sequence('cjdb_associations_id_seq');
__PACKAGE__->has_many('journals', [ 'CJDB::DB::JournalsAssociations' => 'journal' ] );

__PACKAGE__->set_sql(
    'distinct' => qq{
        SELECT DISTINCT ON (search_association) cjdb_associations.* FROM cjdb_associations
        JOIN cjdb_journals_associations ON ( cjdb_journals_associations.association = cjdb_associations.id )
        WHERE site = ? 
        AND search_association LIKE ?
        ORDER BY search_association
    }
);

sub search_distinct_combined {
    my ( $class, $join_type, $site, @search ) = @_;

    # Return an empty set if there were no search terms

    return [] if scalar(@search) == 0;

    my @search_terms = map { '[[:<:]]' . $_ . '[[:>:]]' } @search;

    my $search_string;

    foreach my $x (0 .. $#search_terms - 1) {
        $search_string .= ' cjdb_associations.search_association ~ ? ' . $join_type;
    }
    $search_string .= ' cjdb_associations.search_association ~ ?';

    my $sql = qq{
        SELECT DISTINCT ON (cjdb_associations.search_association, cjdb_associations.id) cjdb_associations.*
        FROM cjdb_associations
        JOIN cjdb_journals_associations ON (cjdb_associations.id = cjdb_journals_associations.association)
        WHERE cjdb_journals_associations.site = ? AND
        ( $search_string )
        ORDER BY search_association;
    };
    
    my @bind = ($site, @search_terms);
    my $sth = $class->db_Main()->prepare( $sql );
    my @results = $class->sth_to_objects( $sth, \@bind );
    return \@results;
}

sub search_distinct_union {
    my ( $class, $site, @search ) = @_;

    return $class->search_distinct_combined( 'OR', $site, @search );
}

sub search_distinct_intersect {
    my ( $class, $site, @search ) = @_;

    return $class->search_distinct_combined( 'AND', $site, @search );
}

1;
