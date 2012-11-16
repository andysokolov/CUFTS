package CUFTS::Schema;

use DBIx::Class::ResultClass::HashRefInflator;

use base qw(DBIx::Class::Schema);
__PACKAGE__->load_classes();

1;
