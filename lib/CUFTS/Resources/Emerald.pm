## CUFTS::Resources::Emerald
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

package CUFTS::Resources::Emerald;

use base qw(CUFTS::Resources::Base::DOI CUFTS::Resources::Base::Journals);

use CUFTS::Exceptions;
use CUFTS::Util::Simple;

use strict;

sub title_list_fields {
    return [
        qw(
            id
            title
            issn
            ft_start_date
            ft_end_date
            vol_ft_start
            vol_ft_end
            iss_ft_start
            iss_ft_end
            journal_url
        )
    ];
}

sub title_list_field_map {
    return {
        'Full Title of Journal' => 'title',
        'ISSN'                  => 'issn',
        'Access URL'            => 'journal_url',
        'Fulltext Available From'       => 'ft_start_date',
        'Access Available From'         => 'ft_start_date',
        'First Fulltext Online Year'    => 'ft_start_date',
        'First Fulltext Online Volume'  => 'vol_ft_start',
        'First Fulltext Online Issue'   => 'iss_ft_start',
        'Final Fulltext Online Year'    => 'ft_end_date',
        'Final Fulltext Online Volume'  => 'vol_ft_end',
        'Final Fulltext Online Issue'   => 'iss_ft_end',
    };
}

sub clean_data {
    my ( $class, $record ) = @_;

    $record->{title} = trim_string( $record->{title}, '"' );
    $record->{title} =~ s/ \s* \*+ \s* $//xsm;

    if ( defined($record->{ft_start_date}) && $record->{ft_start_date} !~ /^ \d{4} $/xsm ) {
       delete $record->{ft_start_date};
       delete $record->{vol_ft_start};
       delete $record->{iss_ft_start};
    }

    return $class->SUPER::clean_data($record);
}

sub build_linkJournal {
    my ( $class, $schema, $records, $resource, $site, $request ) = @_;

    defined($records) && scalar(@$records) > 0
        or return [];
    defined($resource)
        or CUFTS::Exception::App->throw('No resource defined in build_linkJournal');
    defined($site)
        or CUFTS::Exception::App->throw('No site defined in build_linkJournal');
    defined($request)
        or CUFTS::Exception::App->throw('No request defined in build_linkJournal');

    my @results;
    foreach my $record (@$records) {
        next if is_empty_string( $record->issn );

        my $url = 'http://www.emeraldinsight.com/' . dashed_issn( $record->issn ) . '.htm';

        my $result = new CUFTS::Result($url);
        $result->record($record);
        push @results, $result;
    }

    return \@results;
}

1;
