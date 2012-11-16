## CUFTS::Resources::ProquestMicromedia
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

package CUFTS::Resources::ProquestMicromedia;

use CUFTS::Resources::ProquestLinking;

use base qw(CUFTS::Resources::ProquestLinking);

use CUFTS::Exceptions;
use CUFTS::Util::Simple;

use strict;

my $base_url = 'http://openurl.proquest.com/in?';

sub title_list_fields {
    return [
        qw(
            id
            title
            issn
            ft_start_date
            ft_end_date
            embargo_days
        )
    ];
}

sub overridable_resource_details {
    return undef;
}

sub clean_data {
    my ( $class, $record ) = @_;
    my @errors;

    if ( defined( $record->{ft_start_date} ) ) {
        $record->{ft_start_date} =~ s{ (\d+) / (\d+) / (\d+) }{$3-$1-$2}xsm;
    }

    if ( defined( $record->{ft_end_date} ) ) {
        $record->{ft_end_date} =~ s{ (\d+) / (\d+) / (\d+) }{$3-$1-$2}xsm;
    }

    return \@errors;

}

sub title_list_field_map {
    return {
        'title'          => 'title',
        'issn'           => 'issn',
        'fulltext_start' => 'ft_start_date',
        'fulltext_end'   => 'ft_end_date',
        'embargo_days'   => 'embargo_days',
        'db_identifier'  => 'db_identifier',
    };
}

1;
