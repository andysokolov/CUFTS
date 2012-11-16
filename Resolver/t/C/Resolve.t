
use Test::More tests => 3;
use_ok( Catalyst::Test, 'CUFTS::Resolver' );
use_ok('CUFTS::Resolver::C::Resolve');

ok( request('resolve')->is_success );

