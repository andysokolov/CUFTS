package CUFTS::Schema::CJDBAccounts;

use strict;
use base qw/DBIx::Class::Core/;

use Set::Object;

__PACKAGE__->load_components(qw/ FromValidatorsCUFTS EncodedColumn TimeStamp /);

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
        # encode_column => 1,
        # encode_class  => 'Digest',
        # encode_args   => {
        #     algorithm => 'SHA-1',
        #     format => 'hex'
        # },
        # encode_check_method => 'check_password',
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
__PACKAGE__->has_many( tags => 'CUFTS::Schema::CJDBTags' => 'account' );

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

sub remove_role {
    my ( $self, $role ) = @_;
    my $role_record = $self->result_source->schema->resultset('CJDBRoles')->find({ role => $role });
    if ( !$role_record ) {
        warn("Unable to find role in remove_role: $role");
        return 0;
    }
    $self->accounts_roles({ role => $role_record->id })->delete;
    return 1;
}

sub add_role {
    my ( $self, $role ) = @_;
    my $role_record = $self->result_source->schema->resultset('CJDBRoles')->find({ role => $role });
    if ( !$role_record ) {
        warn("Unable to find role in add_role: $role");
        return 0;
    }
    $self->accounts_roles->find_or_create({ role => $role_record->id });
    return 1;
}

sub tag_summary {
    my ( $self ) = @_;

    my $rs = $self->tags->search({},
        {
            select   => [ 'tag', 'viewing', { 'count' => 'tag' } ],
            as       => [ 'tag', 'viewing', 'count' ],
            group_by => [ 'tag', 'viewing' ],
            order_by => [ 'tag' ],
        }
    );
    $rs->result_class('DBIx::Class::ResultClass::HashRefInflator');

    return [ map { [ $_->{tag}, $_->{viewing}, $_->{count} ] } $rs->all ];
}

1;
