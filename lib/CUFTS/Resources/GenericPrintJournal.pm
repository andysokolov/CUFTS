## CUFTS::Resources::GenericPrintJournal
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

package CUFTS::Resources::GenericPrintJournal;

use base qw(CUFTS::Resources::Base::Journals);

use CUFTS::Exceptions;
use CUFTS::Util::Simple;

use strict;

sub title_list_fields {
    return [
        qw(
            id
            title
            issn
            e_issn
            cit_start_date
            cit_end_date
            ft_start_date
            ft_end_date
            vol_ft_start
            vol_ft_end
            iss_ft_start
            iss_ft_end
            embargo_months
            embargo_days
            current_months
            current_years
            coverage
            publisher
            journal_url
            cjdb_note
            local_note
            journal_auth
        )
    ];
}

sub overridable_resource_details {
    return undef;
}

sub title_list_field_map {
    return {
        'title'          => 'title',
        'issn'           => 'issn',
        'e_issn'         => 'e_issn',
        'fulltext_start' => 'ft_start_date',
        'fulltext_end'   => 'ft_end_date',
        'ft_start_date'  => 'ft_start_date',
        'ft_end_date'    => 'ft_end_date',
        'vol_ft_start'   => 'vol_ft_start',
        'vol_ft_end'     => 'vol_ft_end',
        'iss_ft_start'   => 'iss_ft_start',
        'iss_ft_end'     => 'iss_ft_end',
        'citation_start' => 'cit_start_date',
        'citation_end'   => 'cit_end_date',
        'cit_start_date' => 'cit_start_date',
        'cit_end_date'   => 'cit_end_date',
        'embargo_months' => 'embargo_months',
        'embargo_days'   => 'embargo_days',
        'current_months' => 'current_months',
        'current_years'  => 'current_years',
        'coverage'       => 'coverage',
        'publisher'      => 'publisher',
        'journal_url'    => 'journal_url',
        'cjdb_note'      => 'cjdb_note',
    };
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
        my $result = new CUFTS::Result( $record->journal_url || '' );
        $result->record($record);

        push @results, $result;
    }

    return \@results;
}

sub can_getFulltext {
    return 0;
}

sub can_getTOC {
    return 0;
}

##
## CJDB specific code
##

sub modify_cjdb_link_hash {
    my ( $self, $type, $hash ) = @_;

    # $hash the link hash from the CJDB loader:
    # {
    #    URL => '',
    #    link_type => 1,  # 0 - print, 1 - fulltext, 2 - database
    #    fulltext_coverage => '',
    #    citation_coverage => '',
    #    embargo => '',  # moving wall
    #    current => '',  # moving wall
    # }

    # Hash should be directly modified here, if necessary.

    # Convert fulltext to print

    if ( exists $hash->{urls} ) {
        # New style update_cjdb_fast hash
        foreach my $url ( @{$hash->{urls}} ) {
            $url->[0] = 0;
        }

        $hash->{print_coverage} = delete $hash->{fulltext_coverage};
    }
    else {
        # Old update_cjdb hash
        $hash->{link_type} = 0;
        $hash->{print_coverage} = delete $hash->{fulltext_coverage};
    }

    return 1;
}



1;
