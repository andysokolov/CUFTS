package CUFTS::CJDB::Loader::MARC::Blank;

use base ('CUFTS::CJDB::Loader::MARC');
use URI::Escape;
use CUFTS::CJDB::Util;
use strict;

sub get_link {
	my ($self, $record) = @_;
}

sub get_coverage {
	my ($self, $record) = @_;
}

1;