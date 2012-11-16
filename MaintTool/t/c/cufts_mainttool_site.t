
use Test::More tests => 3;
use_ok( Catalyst::Test, 'CUFTS::MaintTool' );
use_ok('CUFTS::MaintTool::C::CUFTS::MaintTool::Site');

ok( request('cufts_mainttool_site')->is_success );

