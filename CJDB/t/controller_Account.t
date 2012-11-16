use strict;
use warnings;
use Test::More;


use Catalyst::Test 'CUFTS::CJDB';
use CUFTS::CJDB::Controller::Account;

ok( request('/account')->is_success, 'Request should succeed' );
done_testing();
