use strict;
use warnings;

use CUFTS::CJDB4;

my $app = CUFTS::CJDB4->apply_default_middlewares(CUFTS::CJDB4->psgi_app);
$app;

