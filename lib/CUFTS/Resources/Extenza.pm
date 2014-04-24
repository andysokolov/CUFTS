## CUFTS::Resources::Extenza
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

package CUFTS::Resources::Extenza;

use base qw(CUFTS::Resources::Base::SFXLoader CUFTS::Resources::Base::DOI);

use CUFTS::Exceptions;
use CUFTS::Util::Simple;

use Unicode::String qw(utf8);

use strict;

sub title_list_fields {
    return [
        qw(
            id
            title
            issn
            e_issn
            ft_start_date
            vol_ft_start
            iss_ft_start
            ft_end_date
            vol_ft_end
            iss_ft_end
            journal_url
        )
    ];
}

sub overridable_resource_details {
    return undef;
}

sub can_getTOC {
    return 0;
}

sub clean_data {
    my ( $class, $record ) = @_;

    if ( defined($record->{issn}) && $record->{issn} !~ /\d{4}-?\d{3}[xX\d]/ ) {
        delete $record->{issn};
    }

    if ( defined($record->{e_issn}) && $record->{e_issn} !~ /\d{4}-?\d{3}[xX\d]/ ) {
        delete $record->{e_issn};
    }

    $record->{title} = utf8( $record->{title} )->latin1;

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
        next if is_empty_string( $record->journal_url );

        my $result = new CUFTS::Result( $record->journal_url );
        $result->record($record);

        push @results, $result;
    }

    return \@results;
}

1;
