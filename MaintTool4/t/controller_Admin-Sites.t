use strict;
use warnings;
use Test::More;


use Catalyst::Test 'CUFTS::MaintTool4';
use CUFTS::MaintTool4::Controller::Admin::Sites;

ok( request('/admin/sites')->is_success, 'Request should succeed' );
done_testing();
