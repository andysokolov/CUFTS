## CUFTS::Resources::SIRSI
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

package CUFTS::Resources::SIRSI;

use base qw(CUFTS::Resources::Base::Catalog);
use CUFTS::Exceptions;
use CUFTS::Result;
use strict;


sub services {
    return [ qw( holdings ) ];
}

sub local_resource_details {
    return [qw(url_base)];
}

sub search_getHoldings {
    my ( $class, $schema, $resource, $site, $request ) = @_;

    my $url = $resource->url_base
        or CUFTS::Exception::App->throw('No url_base defined for SIRSI resource.');

    if ( not_empty_string( $request->issn ) ) {
        my $issn = $request->issn;
        $issn =~ s/^ (\d{4}) -? ( \d{3} [\dxX] ) $/$1-$2/xsm;
        $url .= "uhtbin/cgisirsi/x/0/57/5?user_id=WUAARCHIVE&searchdata1=${issn}\{022\}";
    }
    else {
        return undef;
    }

    my $result = new CUFTS::Result;
    $result->url($url);

    return [$result];
}

1;
