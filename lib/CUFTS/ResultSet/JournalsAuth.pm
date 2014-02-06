package CUFTS::ResultSet::JournalsAuth;

use strict;
use base 'DBIx::Class::ResultSet';

sub search_by_issns {
    my ($self, @issns) = @_;

    return 0 if scalar @issns;

    my @final = grep { /^\d{7}[\dX]$/ } map { uc($_); $_ =~ tr/0-9X//cd; $_ } @issns;

    return $self->resultset('JournalsAuth')->search(
        {
            issn => { '-in' => \@final },
        },
        {
            join => [ 'journals_auth_issns' ],
        }
    );
}

1;