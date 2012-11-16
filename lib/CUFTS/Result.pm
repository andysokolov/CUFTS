## CUFTS::Result
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

package CUFTS::Result;

use CUFTS::Exceptions;
use CUFTS::Util::Simple;

use base qw(Class::Accessor);

use strict;

__PACKAGE__->mk_accessors(
    qw(
        url
        atitle
        record
        site
    )
);

sub new {
    my ( $class, $url ) = @_;

    my $self = bless {}, $class;
    if ( not_empty_string($url) ) {
        $self->url($url);
    }

    return $self;
}

1;
