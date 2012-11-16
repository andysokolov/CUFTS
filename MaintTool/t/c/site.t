
use Test::More tests => 3;
use_ok( Catalyst::Test, 'CUFTS::MaintTool' );
use_ok('CUFTS::MaintTool::C::Site');

ok( request('site')->is_success );

