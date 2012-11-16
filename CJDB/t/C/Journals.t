
use Test::More tests => 3;
use_ok( Catalyst::Test, 'CUFTS::CJDB' );
use_ok('CUFTS::CJDB::C::Journals');

ok( request('journals')->is_success );

