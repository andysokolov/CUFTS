use strict;
use warnings;
use Test::More;


use Catalyst::Test 'CUFTS::CRDB4';
use CUFTS::CRDB4::Controller::Browse;

ok( request('/browse')->is_success, 'Request should succeed' );
done_testing();
