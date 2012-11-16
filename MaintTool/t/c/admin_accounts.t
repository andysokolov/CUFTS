
use Test::More tests => 3;
use_ok( Catalyst::Test, 'CUFTS::MaintTool' );
use_ok('CUFTS::MaintTool::C::Admin::Accounts');

ok( request('admin_accounts')->is_success );

