use strict;
use warnings;
use Test::More;


use Catalyst::Test 'CUFTS::MaintTool4';
use CUFTS::MaintTool4::Controller::Site;

ok( request('/site')->is_success, 'Request should succeed' );
done_testing();
