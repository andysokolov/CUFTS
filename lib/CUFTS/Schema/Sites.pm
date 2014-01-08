package CUFTS::Schema::Sites;

use strict;

use base qw/DBIx::Class::Core/;

__PACKAGE__->load_components(qw//);

__PACKAGE__->table('sites');
__PACKAGE__->add_columns(
    id => {
      data_type => 'integer',
      is_auto_increment => 1,
      default_value => undef,
      is_nullable => 0,
    },
    key => {
      data_type => 'varchar',
      default_value => undef,
      is_nullable => 1,
      size => '64'
    },
    name => {
      data_type => 'varchar',
      default_value => undef,
      is_nullable => 1,
      size => '256'
    },
    proxy_prefix => {
      data_type => 'varchar',
      default_value => undef,
      is_nullable => 1,
      size => '512'
    },
    proxy_WAM => {
      data_type => 'varchar',
      default_value => undef,
      is_nullable => 1,
      size => '512'
    },
    proxy_prefix_alternate => {
      data_type => 'varchar',
      default_value => undef,
      is_nullable => 1,
      size => '512'
    },
    email => {
      data_type => 'varchar',
      default_value => undef,
      is_nullable => 1,
      size => '1024'
    },
    erm_notification_email => {
      data_type => 'varchar',
      default_value => undef,
      is_nullable => 1,
      size => '1024'
    },
    cjdb_results_per_page => {
      data_type => 'varchar',
      default_value => undef,
      is_nullable => 1,
      size => '1024'
    },
    cjdb_unified_journal_list => {
      data_type => 'varchar',
      default_value => undef,
      is_nullable => 1,
      size => '1024'
    },
    cjdb_show_citations => {
      data_type => 'varchar',
      default_value => undef,
      is_nullable => 1,
      size => '1024'
    },
    cjdb_hide_citation_coverage => {
      data_type => 'varchar',
      default_value => undef,
      is_nullable => 1,
      size => '1024'
    },
    cjdb_display_db_name_only => {
      data_type => 'varchar',
      default_value => undef,
      is_nullable => 1,
      size => '1024'
    },
    cjdb_print_name => {
      data_type => 'varchar',
      default_value => undef,
      is_nullable => 1,
      size => '1024'
    },
    cjdb_print_link_label => {
      data_type => 'varchar',
      default_value => undef,
      is_nullable => 1,
      size => '1024'
    },
    cjdb_authentication_module => {
      data_type => 'varchar',
      default_value => undef,
      is_nullable => 1,
      size => '1024'
    },
    cjdb_authentication_server => {
      data_type => 'varchar',
      default_value => undef,
      is_nullable => 1,
      size => '1024'
    },
    cjdb_authentication_string1 => {
      data_type => 'varchar',
      default_value => undef,
      is_nullable => 1,
      size => '1024'
    },
    cjdb_authentication_string2 => {
      data_type => 'varchar',
      default_value => undef,
      is_nullable => 1,
      size => '1024'
    },
    cjdb_authentication_string3 => {
      data_type => 'varchar',
      default_value => undef,
      is_nullable => 1,
      size => '1024'
    },
    cjdb_authentication_level100 => {
      data_type => 'varchar',
      default_value => undef,
      is_nullable => 1,
      size => '1024'
    },
    cjdb_authentication_level50 => {
      data_type => 'varchar',
      default_value => undef,
      is_nullable => 1,
      size => '1024'
    },
    marc_dump_856_link_label => {
      data_type => 'varchar',
      default_value => undef,
      is_nullable => 1,
      size => '1024'
    },
    marc_dump_duplicate_title_field => {
      data_type => 'varchar',
      default_value => undef,
      is_nullable => 1,
      size => '1024'
    },
    marc_dump_cjdb_id_field => {
      data_type => 'varchar',
      default_value => undef,
      is_nullable => 1,
      size => '1024'
    },
    marc_dump_cjdb_id_indicator1 => {
      data_type => 'varchar',
      default_value => undef,
      is_nullable => 1,
      size => '1024'
    },
    marc_dump_cjdb_id_indicator2 => {
      data_type => 'varchar',
      default_value => undef,
      is_nullable => 1,
      size => '1024'
    },
    marc_dump_cjdb_id_subfield => {
      data_type => 'varchar',
      default_value => undef,
      is_nullable => 1,
      size => '1024'
    },
    marc_dump_holdings_field => {
      data_type => 'varchar',
      default_value => undef,
      is_nullable => 1,
      size => '1024'
    },
    marc_dump_holdings_indicator1 => {
      data_type => 'varchar',
      default_value => undef,
      is_nullable => 1,
      size => '1024'
    },
    marc_dump_holdings_indicator2 => {
      data_type => 'varchar',
      default_value => undef,
      is_nullable => 1,
      size => '1024'
    },
    marc_dump_holdings_subfield => {
      data_type => 'varchar',
      default_value => undef,
      is_nullable => 1,
      size => '1024'
    },
    marc_dump_medium_text => {
      data_type => 'varchar',
      default_value => undef,
      is_nullable => 1,
      size => '1024'
    },
    marc_dump_direct_links => {
        'data_type'     => 'boolean',
        default_value => 0,
    },
    rebuild_cjdb => {
      data_type => 'varchar',
      default_value => undef,
      is_nullable => 1,
      size => '1024'
    },
    rebuild_MARC => {
      data_type => 'varchar',
      default_value => undef,
      is_nullable => 1,
      size => '1024'
    },
    rebuild_ejournals_only => {
      data_type => 'varchar',
      default_value => undef,
      is_nullable => 1,
      size => '1024'
    },
    show_ERM => {
      data_type => 'varchar',
      default_value => undef,
      is_nullable => 1,
      size => '1024'
    },
    test_MARC_file => {
      data_type => 'varchar',
      default_value => undef,
      is_nullable => 1,
      size => '1024'
    },
    google_scholar_on => {
      data_type => 'varchar',
      default_value => undef,
      is_nullable => 1,
      size => '1024'
    },
    google_scholar_keywords => {
      data_type => 'varchar',
      default_value => undef,
      is_nullable => 1,
      size => '1024'
    },
    google_scholar_e_link_label => {
      data_type => 'varchar',
      default_value => undef,
      is_nullable => 1,
      size => '1024'
    },
    google_scholar_other_link_label => {
      data_type => 'varchar',
      default_value => undef,
      is_nullable => 1,
      size => '1024'
    },
    google_scholar_openurl_base => {
      data_type => 'varchar',
      default_value => undef,
      is_nullable => 1,
      size => '1024'
    },
    google_scholar_other_xml => {
      data_type => 'varchar',
      default_value => undef,
      is_nullable => 1,
      size => '1024'
    },
    active => {
      data_type => 'boolean',
      default_value => 'TRUE',
      is_nullable => 1,
      size => 0
    },
    created => {
      data_type => 'timestamp',
      default_value => 'NOW()',
      is_nullable => 0,
      size => 0
    },
    modified => {
      data_type => 'timestamp',
      default_value => 'NOW()',
      is_nullable => 0,
      size => 0
    },
);
__PACKAGE__->set_primary_key( 'id' );

# __PACKAGE__->has_many( 'accounts', [ 'CUFTS::DB::Accounts_Sites' => 'account' ], 'site' );

__PACKAGE__->has_many( ips             => 'CUFTS::Schema::SiteIPs',        'site' );
__PACKAGE__->has_many( domains         => 'CUFTS::Schema::SiteDomains',    'site' );
__PACKAGE__->has_many( local_resources => 'CUFTS::Schema::LocalResources', 'site' );
__PACKAGE__->has_many( cjdb_accounts   => 'CUFTS::Schema::CJDBAccounts',   'site' );


sub inflate_packed_field_lists {
    return { map { my ($f,$v) = split(':', $_); $f => $v } split(',', shift) }
}

sub deflate_packed_field_lists {
    my $hash = shift;
    my @list;
    while ( my ($f,$v) = each(%$hash) ) {
        push @list, "$f:$v";
    }
    return join( ',', @list );
}

# __PACKAGE__->inflate_column( 'erm_patron_fields', {
#     inflate => \&inflate_packed_field_lists,
#     deflate => \&deflate_packed_field_lists,
# } );
# __PACKAGE__->inflate_column( 'erm_staff_fields', {
#     inflate => \&inflate_packed_field_lists,
#     deflate => \&deflate_packed_field_lists,
# } );



1;
