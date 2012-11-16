package CUFTS::MaintTool::M::CDBI;

use strict;
use base 'Catalyst::Base';

use CUFTS::DB::DBI;

##
## Jump into the CUFTS::DB::DBI package and load up FromForm.
## We do this so we don't have to carry it around when we're 
## doing offline scripts
##

package CUFTS::DB::DBI;

use Class::DBI::CUFTS::MaintTool::FromForm;

package CUFTS::MaintTool::M::CDBI;

use CUFTS::DB::Accounts;
use CUFTS::DB::Sites;

use CUFTS::DB::Resources;

use CUFTS::DB::Journals;
use CUFTS::DB::JournalsActive;

use CUFTS::DB::Stats;




=head1 NAME

CUFTS::MaintTool::M::CDBI - CDBI CUFTS DB Loader

=head1 SYNOPSIS

Loads all the CUFTS DB modules.

=head1 DESCRIPTION

Loads all the CUFTS DB modules.

=head1 AUTHOR

Todd Holbrook

=head1 LICENSE

This library is free software . You can redistribute it and/or modify 
it under the same terms as perl itself.

=cut

1;

