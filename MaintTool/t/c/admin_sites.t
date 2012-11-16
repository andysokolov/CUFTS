
use Test::More tests => 3;
use_ok( Catalyst::Test, 'CUFTS::MaintTool' );
use_ok('CUFTS::MaintTool::C::Admin::Sites');

ok( request('admin_sites')->is_success );

