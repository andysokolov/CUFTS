use Test::More tests => 2;
use_ok( Catalyst::Test, 'CUFTS::MaintTool' );

ok( request('/')->is_success );

