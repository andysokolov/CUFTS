package CUFTS::Schema;

use DBIx::Class::ResultClass::HashRefInflator;

use base qw(DBIx::Class::Schema);
__PACKAGE__->load_classes();


sub get_now {
    return shift->storage->dbh_do(
        sub {
            my ($storage, $dbh) = @_;
            my @row = $dbh->selectrow_array("SELECT CURRENT_TIMESTAMP");
            return $row[0];
        }
    );
}

1;
