use strict;
use warnings;
use Test::More;


use Catalyst::Test 'CUFTS::CJDB4';
use CUFTS::CJDB4::Controller::Account;

ok( request('/account')->is_success, 'Request should succeed' );
done_testing();
