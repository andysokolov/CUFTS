package CUFTS::ResultSet::CJDBLinks;

use strict;
use base 'DBIx::Class::ResultSet';

sub search_display_notes {
    my ( $self, $search ) = @_;
    $search = {} if !defined($search);

    return $self->search( $search, 
        {
            '+select' => \'COALESCE(local_journal.cjdb_note, global_journal.cjdb_note)',
            '+as' => 'journal_cjdb_note',
            'join' => { 'local_journal' => 'global_journal' },
        }
    );

}

1;