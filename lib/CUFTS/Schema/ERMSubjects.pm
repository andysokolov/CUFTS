package CUFTS::Schema::ERMSubjects;

use strict;
use base qw/DBIx::Class::Core/;

__PACKAGE__->load_components(qw//);

__PACKAGE__->table('erm_subjects');
__PACKAGE__->add_columns( qw(
    id
    site
    subject
    description
));

__PACKAGE__->set_primary_key( 'id' );

1;

