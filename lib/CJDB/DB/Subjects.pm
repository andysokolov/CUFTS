## CJDB::DB::Subjects
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

package CJDB::DB::Subjects;

use strict;
use base 'CJDB::DB::DBI';
use CJDB::DB::Journals;

__PACKAGE__->table('cjdb_subjects');
__PACKAGE__->columns( Primary => 'id' );
__PACKAGE__->columns(
    All => qw(
        id
        subject
        search_subject
    )
);
__PACKAGE__->columns( Essential => __PACKAGE__->columns );
__PACKAGE__->sequence('cjdb_subjects_id_seq');
__PACKAGE__->has_many('journals', [ 'CJDB::DB::JournalsSubjects' => 'journal' ] );

__PACKAGE__->set_sql(
    'distinct' => qq{
        SELECT DISTINCT ON (search_subject) cjdb_subjects.* FROM cjdb_subjects
        JOIN cjdb_journals_subjects ON ( cjdb_journals_subjects.subject = cjdb_subjects.id )
        WHERE site = ? 
        AND search_subject LIKE ?
        ORDER BY search_subject
    }
);

sub search_distinct_combined {
    my ( $class, $join_type, $site, @search ) = @_;

    # Return an empty set if there were no search terms

    return [] if scalar(@search) == 0;

    my @search_terms = map { '[[:<:]]' . $_ . '[[:>:]]' } @search;

    my $search_string;

    foreach my $x (0 .. $#search_terms - 1) {
        $search_string .= ' cjdb_subjects.search_subject ~ ? ' . $join_type;
    }
    $search_string .= ' cjdb_subjects.search_subject ~ ?';

    my $sql = qq{
        SELECT DISTINCT ON (cjdb_subjects.search_subject, cjdb_subjects.id) cjdb_subjects.*
        FROM cjdb_subjects
        JOIN cjdb_journals_subjects ON (cjdb_subjects.id = cjdb_journals_subjects.subject)
        WHERE cjdb_journals_subjects.site = ? AND
        ( $search_string )
        ORDER BY search_subject;
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
