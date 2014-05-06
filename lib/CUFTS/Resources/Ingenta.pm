## CUFTS::Resources::Ingenta
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

package CUFTS::Resources::Ingenta;

use base qw(CUFTS::Resources::Base::DOI CUFTS::Resources::Base::Journals);

use HTML::Entities;
use CUFTS::Exceptions;
use CUFTS::Util::Simple;

use strict;

sub services {
    return [ qw( fulltext journal database ) ];
}

sub title_list_fields {
    return [
        qw(
            id
            title
            issn
            e_issn

            ft_start_date
            ft_end_date

            vol_ft_start
            vol_ft_end

            iss_ft_start
            iss_ft_end

            publisher
            journal_url
            )
    ];
}

sub clean_data {
    my ( $self, $record ) = @_;

    $record->{title} = HTML::Entities::decode_entities( $record->{title} );

    if ( defined( $record->{'___Availability'} )
         && $record->{'___Availability'} =~ / (\d{4}) \s* - \s* (\d{4}) /xsm )
    {
        $record->{ft_start_date} = $1;
        $record->{ft_end_date}   = $2;
    }
    elsif ( defined( $record->{'___Availability'} )
        && $record->{'___Availability'} =~ /(\d{4})/ )
    {
        $record->{ft_start_date} = $1;
    }

    return $self->SUPER::clean_data($record);
}

sub title_list_field_map {
    return {
        'Title'      => 'title',
        'ISSN'       => 'issn',
        'E-ISSN'     => 'e_issn',
        'Publisher'  => 'publisher',
        'Direct URL' => 'journal_url',
    };
}

sub skip_record {
    my ( $self, $record ) = @_;

    return not_empty_string( $record->{'___ISBN'} );
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

sub can_getFulltext {
    my ( $class, $request ) = @_;

    return 0 if is_empty_string( $request->date  );
    return 0 if is_empty_string( $request->spage );

    return $class->SUPER::can_getFulltext($request);
}


sub build_linkFulltext {
    my ( $class, $schema, $records, $resource, $site, $request ) = @_;

    defined($records) && scalar(@$records) > 0
        or return [];
    defined($resource)
        or CUFTS::Exception::App->throw('No resource defined in build_linkFulltext');
    defined($site)
        or CUFTS::Exception::App->throw('No site defined in build_linkFulltext');
    defined($request)
        or CUFTS::Exception::App->throw('No request defined in build_linkFulltext');

    my @results;

    foreach my $record (@$records) {
        next if is_empty_string( $record->issn   );

        my $url = 'http://www.ingentaselect.com/rpsv/cgi-bin/cgi?body=linker&reqidx=';
        $url .= $record->issn;

        $url .= '(' . $request->date . ')';

        if ( not_empty_string($request->volume) ) {
            $url .= $request->volume;
        }

        if ( not_empty_string($request->issue) ) {
             $url .= ':' . $request->issue;
        }

        $url .= 'L.' . $request->spage;

        my $result = new CUFTS::Result($url);
        $result->record($record);

        push @results, $result;
    }

    return \@results;
}

1;
