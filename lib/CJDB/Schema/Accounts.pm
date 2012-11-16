package CJDB::Schema::Accounts;

use strict;
use base qw/DBIx::Class/;

use Set::Object;

__PACKAGE__->load_components(qw/PK::Auto Core/);
__PACKAGE__->table('cjdb_accounts');
__PACKAGE__->add_columns( qw(
    id

    name
    key
    password
    email
    level

    site

    active

    created
    modified
));                                                                                                        

__PACKAGE__->set_primary_key('id');

__PACKAGE__->resultset_class('CJDB::ResultSet::Accounts');

__PACKAGE__->has_many(
    map_user_role => 'CJDB::Schema::AccountsRoles' => 'account'
);
__PACKAGE__->many_to_many( roles => 'map_user_role', 'role');

# Returns a string mapping to the level of access granted to this account.  It
# can be used to check what fields should be displayed to the user, what goes into
# a JSON record dump, etc.

sub get_account_type {
    my ( $self ) = @_;

    my $account_roles = Set::Object->new( map { $_->role } $self->roles );
    my $need_roles = Set::Object->new( ( 'edit_erm_records', 'view_erm_records' ) );
    
    return 'staff' if $account_roles->intersection($need_roles)->size > 0;

    # default to lowest level
    
    return 'patron';
}



1;