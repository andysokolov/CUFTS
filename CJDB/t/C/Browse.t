
use Test::More tests => 3;
use_ok( Catalyst::Test, 'CUFTS::CJDB' );
use_ok('CUFTS::CJDB::C::Browse');

ok( request('browse')->is_success );

