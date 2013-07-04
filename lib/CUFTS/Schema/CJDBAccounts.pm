package CUFTS::Schema::CJDBAccounts;

use strict;
use base qw/DBIx::Class::Core/;

use Set::Object;

__PACKAGE__->load_components(qw/EncodedColumn/);
__PACKAGE__->table('cjdb_accounts');
__PACKAGE__->add_columns(
    id => {
      data_type => 'integer',
      is_auto_increment => 1,
      is_nullable => 0,
    },
    key => {
      data_type => 'varchar',
      is_nullable => 0,
      size => 64,
    },
    site => {
        data_type => 'integer',
        is_nullable => 0,
    },
    name => {
        data_type => 'varchar',
        is_nullable => 0,
        size => 256,
    },
    password => {
        data_type => 'char',
        is_nullable => 0,
        size => 40,
        encode_column => 1,
        encode_class  => 'Digest',
        encode_args   => {
            algorithm => 'SHA-1',
            format => 'hex'
        },
        encode_check_method => 'check_password',
    },
    email => {
        data_type => 'varchar',
        is_nullable => 0,
        size => 256,
    },
    level => {
        data_type => 'integer',
        is_nullable => 1,
        default_value => 0,
    },
    active => {
        data_type => 'boolean',
        is_nullable => 0,
        default_value => 'true',
    },
    created => {
        data_type => 'datetime',
        set_on_create => 1,
    },
    modified => {
        data_type => 'datetime',
        set_on_create => 1,
        set_on_update => 1,
    },
);

__PACKAGE__->set_primary_key('id');

# __PACKAGE__->resultset_class('CUFTS::ResultSet::CJDBAccounts');

__PACKAGE__->belongs_to( site => 'CUFTS::Schema::Sites');

__PACKAGE__->has_many( accounts_roles => 'CUFTS::Schema::CJDBAccountsRoles' => 'account' );
__PACKAGE__->many_to_many( roles => 'accounts_roles', 'role');

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

sub has_role {
    my ( $self, $role ) = @_;
    return !!scalar grep { $_->role eq $role } $self->roles;
}



1;