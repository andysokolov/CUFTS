## CUFTS::Config
##
## Copyright Todd Holbrook - Simon Fraser University (2003)
##
## This file is part of CUFTS.
##
## CUFTS is free software; you can redistribute it and/or modify it under
## the terms of the GNU General Public License as published by the Free
## Software Foundation; either version 2 of the License, or (at your option)
## any later version.
##
## CUFTS is distributed in the hope that it will be useful, but WITHOUT ANY
## WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
## FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
## details.
##
## You should have received a copy of the GNU General Public License along
## with CUFTS; if not, write to the Free Software Foundation, Inc., 59
## Temple Place, Suite 330, Boston, MA 02111-1307 USA

# This simply loads the basic and advanced config options into the same package for
# easy use by other classes.  The installation script should set up the BasicConfig.pm
# file for you, or you can edit it to change things like the base install directory,
# database name, etc.  AdvancedConfig contains stuff like built up database connection
# strings, etc.

package CUFTS::Config;

use CUFTS::BasicConfig;
use CUFTS::AdvancedConfig;

use CUFTS::Schema;

sub get_schema {
	return CUFTS::Schema->connect( $CUFTS::Config::CUFTS_DB_STRING, 
								   $CUFTS::Config::CUFTS_USER, 
								   $CUFTS::Config::CUFTS_PASSWORD, 
#								   { quote_names => 1 }
	);
}

1;
