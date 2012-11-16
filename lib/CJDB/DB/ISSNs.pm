## CJDB::DB::ISSNs
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

package CJDB::DB::ISSNs;

use strict;
use base 'CJDB::DB::DBI';
use CJDB::DB::Journals;

__PACKAGE__->table('cjdb_issns');
__PACKAGE__->columns( Primary => 'id' );
__PACKAGE__->columns(
    All => qw(
        id

        journal
        issn

        site
    )
);
__PACKAGE__->columns( Essential => __PACKAGE__->columns );
__PACKAGE__->sequence('cjdb_issns_id_seq');
__PACKAGE__->has_a( 'journal' => 'CJDB::DB::Journals' );

sub normalize_column_values {
    my ( $self, $values ) = @_;

    # Check ISSNs for dashes and strip them out

    if (   exists( $values->{'issn'} )
        && defined( $values->{'issn'} )
        && $values->{'issn'} ne '' )
    {
        $values->{'issn'} = uc( $values->{'issn'} );
        $values->{'issn'} =~ s/(\d{4})\-?(\d{3}[\dxX])/$1$2/
            or $self->_croak( 'issn is not valid: ' . $values->{'issn'} );
    }

    return 1;
}

sub search_issnlist {
    my ( $class, $site, $issn, $offset, $limit ) = @_;

    $limit  ||= 'ALL';
    $offset ||= 0;

    $issn =~ s/\-//g;

    my $sql = "SELECT DISTINCT on (issn) issn, title FROM cjdb_issns JOIN cjdb_journals ON (cjdb_journals.id = cjdb_issns.journal) WHERE cjdb_issns.site = ? AND cjdb_issns.issn LIKE ? ORDER BY issn LIMIT $limit OFFSET $offset";
    my $dbh = $class->db_Main();
    my $sth = $dbh->prepare( $sql );

    $sth->execute( $site, $issn );
    my $results = $sth->fetchall_arrayref;
    return $results;
}

1;
