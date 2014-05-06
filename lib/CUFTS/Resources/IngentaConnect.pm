## CUFTS::Resources::IngentaConnect
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

package CUFTS::Resources::IngentaConnect;

use base qw(CUFTS::Resources::Base::DOI CUFTS::Resources::Base::Journals);

use HTML::Entities;
use CUFTS::Exceptions;
use CUFTS::Util::Simple;

use strict;

sub services {
    return [ qw( fulltext journal database ) ];
}

sub title_list_extra_requires {
    require CUFTS::Util::CSVParse;
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

sub overridable_resource_details {
    return undef;
}

sub clean_data {
    my ( $class, $record ) = @_;

    $record->{title} = HTML::Entities::decode_entities( $record->{title} );

    # An "E" in the ISSN probably indicates it's in scientific notation and really a long ISBN
    if ( defined($record->{issn}) && ( length($record->{issn}) > 9 || $record->{issn} =~ /E/ ) ) {
        return [ 'Skipping monograph with ISBN: ' . $record->{issn} ];
    }

    if ( defined( $record->{ft_start_date} ) ) {

        if ( $record->{ft_start_date} =~ / (\d{4}) \s* - \s* (\d{4}) /xsm ) {
            $record->{ft_start_date} = $1;
            $record->{ft_end_date}   = $2;
        }
        elsif ( $record->{ft_start_date} =~ /^ (\d{4}) /xsm ) {
            $record->{ft_start_date} = $1;
        }
        else {
            delete $record->{ft_start_date};
        }

    }

    if ( defined( $record->{e_issn} )
         && ( $record->{e_issn} =~ /0000\-?0000/ || $record->{e_issn} =~ /unknown/ )
       )
    {
        delete $record->{e_issn};
    }

    if ( defined( $record->{issn} )
         && ( $record->{issn} =~ /0000\-?0000/ || $record->{issn} =~ /unknown/ )
       )
    {
        delete $record->{issn};
    }

    if ( $record->{___vol_range} =~ m{^ (\d+)/(\d+) - (\d+)/(\d+) $}msx ) {
        $record->{vol_ft_start} = $1;
        $record->{iss_ft_start} = $2;
        $record->{vol_ft_end}   = $3;
        $record->{iss_ft_start} = $4;
    }

    my $year = (localtime())[5] + 1900;
    if ( defined($record->{ft_end_date}) && $record->{ft_end_date} >= ($year - 1) ) {
        delete $record->{ft_end_date};
        delete $record->{vol_ft_end};
        delete $record->{iss_ft_end};
    }

    return $class->SUPER::clean_data($record);
}

sub title_list_split_row {
    my ( $class, $row ) = @_;

    my $csv = CUFTS::Util::CSVParse->new();

    $row = trim_string($row);

    $csv->parse($row)
        or CUFTS::Exception::App->throw('Error parsing CSV line: ' . $csv->error_input() );

    my @fields = $csv->fields;
    return \@fields;
}

sub title_list_get_field_headings {
    return [
        qw(
            publisher
            title
            issn
            e_issn
            ft_start_date
            ___vol_range
            journal_url
        )
    ];
}

## preprocess_file - Join the multi-line style of title list into one title list
##                   write a temp file and open it.  In this case, we're just deleting
##                   tons of duplicate lines

# sub preprocess_file {
#     my ( $class, $IN ) = @_;
#
#     use File::Temp;
#
#     my ( $fh, $filename ) = File::Temp::tempfile();
#     my %seen;
#
#     # publisher, title, issn, e_issn, coverage, url
#     while ( my $line = <$IN> ) {
#         my ( $publisher, $title, $issn, $e_issn, $coverage, $url )
#             = @{ $class->title_list_split_row($line) };
#
#         if ( !defined( $seen{$url} ) ) {
#             $seen{$url} = {};
#         }
#
#         $seen{$url}->{publisher} ||= $publisher;
#         $seen{$url}->{title}     ||= $title;
#
#         my @temp_issns;
#         if ( defined($issn)
#              && $issn ne '0000-0000'
#              && $issn =~ /\d{4}-\d{3}[\dxX]/ )
#         {
#             push @temp_issns, $issn;
#         }
#
#
#         if ( defined($e_issn)
#             && $e_issn ne '0000-0000'
#             && $e_issn =~ /\d{4}-\d{3}[\dxX]/ )
#         {
#             push @temp_issns, $e_issn;
#         }
#
#         foreach my $temp_issn (@temp_issns) {
#
#             if ( !defined( $seen{$url}->{issns} ) ) {
#                 $seen{$url}->{issns} = [];
#             }
#
#             push @{ $seen{$url}->{issns} }, $temp_issn;
#         }
#
#         my ( $temp_start, $temp_end ) = split /-/, $coverage;
#
#         if (defined($temp_start)
#             && ( !defined( $seen{$url}->{start} )
#                 || $temp_start < $seen{$url}->{start} )
#             )
#         {
#             $seen{$url}->{start} = $temp_start;
#         }
#
#         if (defined($temp_end)
#             && ( !defined( $seen{$url}->{end} )
#                 || $temp_end > $seen{$url}->{end} )
#             )
#         {
#             $seen{$url}->{end} = $temp_end;
#         }
#     }
#
#     foreach my $url ( keys %seen ) {
#         print $fh '"', $seen{$url}->{publisher}, '",';
#         print $fh '"', $seen{$url}->{title},     '",';
#
#         if ( defined( $seen{$url}->{issns} ) ) {
#             print $fh shift( @{ $seen{$url}->{issns} } );
#         }
#         print $fh ',';
#
#         if ( defined( $seen{$url}->{issns} ) ) {
#             print $fh shift( @{ $seen{$url}->{issns} } );
#         }
#         print $fh ',';
#
#         print $fh $seen{$url}->{start}, '-', $seen{$url}->{end}, ',';
#
#         print $fh $url;
#         print $fh "\n";
#     }
#
#     close *$IN;
#     seek *$fh, 0, 0;
#
#     return $fh;
# }

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
        next if is_empty_string( $record->issn );

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
