package CUFTS::ResultSet::JournalsAuth;

use strict;
use base 'DBIx::Class::ResultSet';

sub search_by_issns {
    my ($self, @issns) = @_;

    my @final = grep { /^\d{7}[\dX]$/ } map { my $a = uc($_); $a =~ tr/0-9X//cd; $a } @issns;

    return $self->search(
        {
            'issns.issn' => { '-in' => \@final },
        },
        {
            distinct => 1,
            join => [ 'issns' ],
        }
    );
}

sub search_by_title {
    my ($self, $title) = @_;

    return $self->search(
        {
            'titles.title'  => { 'ilike' => $title },
        },
        {
            distinct => 1,
            join => [ 'titles' ],
        }
    );
}

sub search_by_exact_title_with_no_issns {
    my ($self, $title) = @_;

    return $self->search(
        {
            title         => { 'ilike' => $title },
            'issns.issn'  => undef,
        },
        {
            join => [ 'issns' ],
        }
    );
}


sub search_by_title_with_no_issns {
    my ($self, $title) = @_;

    return $self->search(
        {
            'titles.title'  => { 'ilike' => $title },
            'issns.issn'    => undef,
        },
        {
            distinct => 1,
            join => [ 'issns', 'titles' ],
        }
    );
}


1;