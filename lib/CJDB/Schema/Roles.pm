package CJDB::Schema::Roles;

use strict;
use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto Core/);
__PACKAGE__->table('cjdb_roles');
__PACKAGE__->add_columns( qw(
    id
    role
));                                                                                                        

__PACKAGE__->set_primary_key('id');


1;