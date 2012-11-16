
use Test::More tests => 3;
use_ok( Catalyst::Test, 'CUFTS::MaintTool' );
use_ok('CUFTS::MaintTool::C::Admin');

ok( request('admin')->is_success );

