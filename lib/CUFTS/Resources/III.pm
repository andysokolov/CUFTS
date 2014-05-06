## CUFTS::Resources::III
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

package CUFTS::Resources::III;

use base qw(CUFTS::Resources::Base::Catalog);
use CUFTS::Exceptions;
use CUFTS::Util::Simple;
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

    not_empty_string( $resource->url_base )
        or CUFTS::Exception::App->throw('No url_base defined for III resource.');

    my $url;
    if ( is_empty_string( $request->issn ) ) {
        $url = 'i?SEARCH=' . $request->issn;
    }
    else {
        return undef;
    }

    my $result = new CUFTS::Result($url);

    return [$result];
}

1;
