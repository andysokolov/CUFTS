package CUFTS::ResultSet::GlobalJournals;

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

sub search_active_local {
    my ( $self, $local_resource_id ) = (shift,shift);

    return $self->search(
        {
            'local_journals.active'   => 't',
            'local_journals.resource' => $local_resource_id,
        },
        {
            join => [ 'local_journals' ],
        }
    )->search(@_);
}

sub search_inactive_local {
    my ( $self, $local_resource_id ) = (shift,shift);

    return $self->search(
        {
            'local_journals.active'   => [ 'f', undef ],
        },
        {
            from => 'journals me LEFT JOIN ( SELECT id, journal, active FROM local_journals WHERE resource = ?) local_journals ON local_journals.journal = me.id',
            bind => [ $local_resource_id ],
        }
    )->search(@_);
}


no Moose;

__PACKAGE__->meta->make_immutable(inline_constructor => 0);

1;
