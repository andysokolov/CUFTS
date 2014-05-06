package CUFTS::ResultSet::ResourcesList;

use strict;
use base 'DBIx::Class::ResultSet';

# search_site must be used to search this resultset because it passes through
# two bound site fields that the unioned virtual view expects.

sub search_site {
    my ( $self, $site ) = @_;

    return $self->search({}, { bind => [ $site, $site ] } );
}

1;