use Test::More tests => 2;
use_ok( Catalyst::Test, 'CUFTS::Resolver' );

ok( request('/')->is_success );
