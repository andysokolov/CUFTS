## CUFTS::Resources::Lexis_Nexis_AC
##
## Copyright Michelle Gauthier - Simon Fraser University (2004)
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

package CUFTS::Resources::Lexis_Nexis_AC;

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
            ft_start_date
            ft_end_date
            cit_start_date
            cit_end_date
            journal_url
            db_identifier
        )
    ];
}

sub title_list_field_map {
    return {
        'Title'            => 'title',
        'ISSN'             => 'issn',
        'Coverage Begin'   => 'ft_start_date',
        'Coverage End'     => 'ft_end_date',
        'csi'              => 'db_identifier',
        'Title Search URL' => 'journal_url',
    };
}


sub skip_record {
    my ( $class, $record ) = @_;

    return 1 if is_empty_string( $record->{'___Coverage Level'} );

    return 1 if is_empty_string( $record->{ft_start_date}  )
             && is_empty_string( $record->{ft_end_date}    )
             && is_empty_string( $record->{cit_start_date} )
             && is_empty_string( $record->{cit_end_date}   );

    return 0;
}


sub clean_data {
    my ( $self, $record ) = @_;

    $record->{title} =~ s/\(.+?\)//g;

    if ( not_empty_string( $record->{ft_start_date} ) ) {
        if ( $record->{ft_start_date} =~ m{ (\d+)/(\d+)/(\d+) }xsm ) {
            $record->{ft_start_date} = sprintf("%04i-%02i-%02i", $3, $1, $2);
        }
        else {
            delete $record->{ft_start_date};
        }
    }

    if ( not_empty_string( $record->{ft_end_date} ) ) {
        if ( $record->{ft_end_date} =~ m{ (\d+)/(\d+)/(\d+) }xsm ) {
            $record->{ft_end_date} = sprintf("%04i-%02i-%02i", $3, $1, $2);
        }
        else {
            delete $record->{ft_end_date};
        }
    }

    # Unless the Coverage Level includes "Full-text", assume it has abstracts only

    if ( not_empty_string( $record->{'___Coverage Level'} ) && $record->{'___Coverage Level'} !~ /full.?text/i ) {
        $record->{cit_start_date} = $record->{ft_start_date};
        $record->{cit_end_date}   = $record->{ft_end_date};
        delete $record->{ft_start_date};
        delete $record->{ft_end_date};
    }

    return $self->SUPER::clean_data($record);
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


sub build_linkDatabase {
    my ( $class, $schema, $records, $resource, $site, $request ) = @_;

    defined($records) && scalar(@$records) > 0
        or return [];
    defined($resource)
        or CUFTS::Exception::App->throw('No resource defined in build_linkDatabase');
    defined($site)
        or CUFTS::Exception::App->throw('No site defined in build_linkDatabase');
    defined($request)
        or CUFTS::Exception::App->throw('No request defined in build_linkDatabase');

    my @results;

    foreach my $record (@$records) {
        my $result = new CUFTS::Result('http://web.lexis-nexis.com/universe');
        $result->record($record);

        push @results, $result;
    }

    return \@results;
}

1;
