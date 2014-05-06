## CUFTS::Resources::LexisNexisAcademic
##
## Copyright Todd Holbrook - Simon Fraser University (2004)
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

package CUFTS::Resources::LexisNexisAcademic;

use base qw(CUFTS::Resources::Base::Journals);

use CUFTS::Exceptions;
use CUFTS::Util::Simple;
use URI::Escape qw(uri_escape);

use strict;

sub services {
    return [ qw( fulltext journal database ) ];
}

sub title_list_extra_requires {
    require CUFTS::Util::CSVParse;
}

sub title_list_split_row {
    my ( $class, $row ) = @_;

    my $csv = CUFTS::Util::CSVParse->new();
    $csv->parse($row)
        or CUFTS::Exception::App->throw('Error parsing CSV line: ' . $csv->error_input() );

    my @fields = $csv->fields;
    return \@fields;
}

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
        'Begin yyyymmdd'   => 'ft_start_date',
        'End yyyymmdd'     => 'ft_end_date',
        'begin_yyyymmdd'   => 'ft_start_date',
        'end_yyyymmdd'     => 'ft_end_date',
        'Article Link CSI' => 'db_identifier',
        'Linking CSI'      => 'db_identifier',
        'Title Search URL' => 'journal_url',
        'Title Level URL'  => 'journal_url',
        'Publisher'        => 'publisher',
    };
}


sub skip_record {
    my ( $class, $record ) = @_;

    return 1 if is_empty_string( $record->{'___Coverage Level'} );

    # return 1 if is_empty_string( $record->{ft_start_date}  )
    #          && is_empty_string( $record->{ft_end_date}    )
    #          && is_empty_string( $record->{cit_start_date} )
    #          && is_empty_string( $record->{cit_end_date}   );

    return 0;
}


sub clean_data {
    my ( $self, $record ) = @_;

    $record->{title} =~ s/\(.+?\)//g;

    if ( not_empty_string( $record->{ft_start_date} ) ) {
        $record->{ft_start_date} =~ s/(\d{4})(\d{2})(\d{2})/$1-$2-$3/;
    }
    else {
        $record->{ft_start_date} = get_date($record->{'___Coverage Begin'});
    }

    if ( not_empty_string( $record->{ft_end_date} ) ) {
        $record->{ft_end_date} =~ s/(\d{4})(\d{2})(\d{2})/$1-$2-$3/;
    }
    else {
        $record->{ft_end_date} = get_date($record->{'___Coverage End'});
    }

    # Unless the Coverage Level includes "Full-text", assume it has abstracts only and move the fulltext dates to citation dates

    if ( not_empty_string( $record->{'___Coverage Level'} ) && $record->{'___Coverage Level'} !~ /full.?text/i ) {
        $record->{cit_start_date} = delete $record->{ft_start_date};
        $record->{cit_end_date}   = delete $record->{ft_end_date};
    }

    return $self->SUPER::clean_data($record);

    sub get_date {
        my ($string) = @_;

        if ( defined($string) && $string =~ /(\d+)-([a-z]{3})-(\d{4})/ig ) {
            my ( $day, $month, $year ) = ( $1, $2, $3 );

            if    ( $month =~ /^Jan/i ) { $month = 1 }
            elsif ( $month =~ /^Feb/i ) { $month = 2 }
            elsif ( $month =~ /^Mar/i ) { $month = 3 }
            elsif ( $month =~ /^Apr/i ) { $month = 4 }
            elsif ( $month =~ /^May/i ) { $month = 5 }
            elsif ( $month =~ /^Jun/i ) { $month = 6 }
            elsif ( $month =~ /^Jul/i ) { $month = 7 }
            elsif ( $month =~ /^Aug/i ) { $month = 8 }
            elsif ( $month =~ /^Sep/i ) { $month = 9 }
            elsif ( $month =~ /^Oct/i ) { $month = 10 }
            elsif ( $month =~ /^Nov/i ) { $month = 11 }
            elsif ( $month =~ /^Dec/i ) { $month = 12 }
            else {
                CUFTS::Exception::App->throw("Unable to find month match in fulltext date: $month");
            }

            return sprintf( "%04i-%02i-%02i", $year, $month, $day );
        }

        return undef;
    }

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
        my $result = new CUFTS::Result('http://www.lexisnexis.com/us/lnacademic');
        $result->record($record);

        push @results, $result;
    }

    return \@results;
}

sub can_getFulltext {
    my ( $class, $request ) = @_;

    return 0 if is_empty_string( $request->atitle )
             && is_empty_string( $request->aulast );
    return $class->SUPER::can_getFulltext($request);
}


sub build_linkFulltext {
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

        my $url = 'http://www.lexisnexis.com/us/lnacademic/api/version1/sr?shr=t&csi='
                  . $record->db_identifier
                  . '&sr=';

        my @search_fields;

        if ( not_empty_string( $request->atitle ) ) {
            my $search_title = lc( $request->atitle );
            $search_title =~ s/\(.+?\)$//;                 # remove trailing (...)
            $search_title =~ s/[^a-z0-9\s]/ /g;            # remove punctuation
            $search_title =~ s/\b\s*(and|or|not)\s*\b//g;  # remove stop words
            $search_title =~ s/\s\s+/ /g;                  # compress spaces
            push @search_fields, ( 'HLEAD(' . uri_escape( $search_title ) . ')' );
        }

        if ( not_empty_string( $request->aulast ) ) {
            my $search_author = lc( $request->aulast );
            $search_author =~ s/[^a-z0-9\s]//g;            # remove punctuation
            $search_author =~ s/\b\s*(and|or|not)\s*\b//g;  # remove stop words
            $search_author =~ s/\s\s+/ /g;                  # compress spaces
            push @search_fields, ( 'BYLINE(' . uri_escape( $search_author ) . ')' );
        }

        if ( not_empty_string( $request->date ) ) {
            push @search_fields, ( 'DATE%20IS%20' . uri_escape($request->date) );

        }

        $url .= join '%20AND%20', @search_fields;

        my $result = new CUFTS::Result($url);
        $result->record($record);

        push @results, $result;
    }

    return \@results;
}

1;
