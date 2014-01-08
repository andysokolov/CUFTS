package CUFTS::Schema::CJDBISSNs;

use strict;
use base qw/DBIx::Class::Core/;

__PACKAGE__->load_components(qw//);

__PACKAGE__->table('cjdb_issns');
__PACKAGE__->add_columns(
    id => {
      data_type => 'integer',
      is_auto_increment => 1,
      is_nullable => 0,
    },
    site => {
        data_type => 'integer',
        is_nullable => 0,
    },
    journal => {
        data_type => 'integer',
        is_nullable => 0,
    },
    issn => {
        data_type => 'varchar',
        is_nullable => 0,
        size => 8,
    },

);

__PACKAGE__->set_primary_key('id');

# Check the ResultSet for more predefined complex searches

# __PACKAGE__->resultset_class('CUFTS::ResultSet::CJDBJournals');

__PACKAGE__->belongs_to( site    => 'CUFTS::Schema::Sites',        'site' );
__PACKAGE__->belongs_to( journal => 'CUFTS::Schema::CJDBJournals', 'journal' );

sub issn_dashed {
    my $self = shift;
    my $issn = $self->issn;
    return substr($issn,0,4) . '-' . substr($issn,4,4);
}

# sub normalize_column_values {
#     my ( $self, $values ) = @_;

#     # Check ISSNs for dashes and strip them out

#     if (   exists( $values->{'issn'} )
#         && defined( $values->{'issn'} )
#         && $values->{'issn'} ne '' )
#     {
#         $values->{'issn'} = uc( $values->{'issn'} );
#         $values->{'issn'} =~ s/(\d{4})\-?(\d{3}[\dxX])/$1$2/
#             or $self->_croak( 'issn is not valid: ' . $values->{'issn'} );
#     }

#     return 1;
# }

# sub search_issnlist {
#     my ( $class, $site, $issn, $offset, $limit ) = @_;

#     $limit  ||= 'ALL';
#     $offset ||= 0;

#     $issn =~ s/\-//g;

#     my $sql = "SELECT DISTINCT on (issn) issn, title FROM cjdb_issns JOIN cjdb_journals ON (cjdb_journals.id = cjdb_issns.journal) WHERE cjdb_issns.site = ? AND cjdb_issns.issn LIKE ? ORDER BY issn LIMIT $limit OFFSET $offset";
#     my $dbh = $class->db_Main();
#     my $sth = $dbh->prepare( $sql );

#     $sth->execute( $site, $issn );
#     my $results = $sth->fetchall_arrayref;
#     return $results;
# }


1;
