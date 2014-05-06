package CUFTS::ResultSet::LocalJournals;

use strict;

use CUFTS::Util::Simple qw(dashed_issn clean_issn);
use CUFTS::Resources::Base::Journals;

use Moose;
extends 'DBIx::Class::ResultSet';

around create => sub {
    my ($orig, $self) = (shift, shift);

    if (@_) {
        my $data = $_[0];

        # Expand YYYY and YYYY-MM dates
        CUFTS::Resources::Base::Journals->clean_data_dates($data);

        $data->{issn}   = clean_issn( $data->{issn} )   if exists $data->{issn};
        $data->{e_issn} = clean_issn( $data->{e_issn} ) if exists $data->{e_issn};

        $self->$orig($data);
    }
    else {
        $self->$orig();
    }
};


no Moose;

__PACKAGE__->meta->make_immutable(inline_constructor => 0);

1;
