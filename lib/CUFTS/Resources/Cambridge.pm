## CUFTS::Resources::Cambridge.pm
##
## Copyright Todd Holbrook - Simon Fraser University (2006-05-09)
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

package CUFTS::Resources::Cambridge;

use base qw(CUFTS::Resources::Base::DOI CUFTS::Resources::Base::Journals);

use CUFTS::Exceptions;
use CUFTS::Util::Simple;

use URI::Escape;

use strict;

my $url_base = 'http://journals.cambridge.org/';

## title_list_fields - Controls what fields get displayed and loaded from
## title lists.
##

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
            db_identifier
        )
    ];
}

sub clean_data {
    my ( $class, $record ) = @_;

    foreach my $field (qw(vol_ft_start  vol_ft_end)) {
        if ( defined( $record->{$field} ) && int( $record->{$field} ) < 0 ) {
            delete $record->{$field};
        }
    }

    if ( $record->{issn} !~ / \d{4} -? \d{3}[\dxX] /xsm ) {
        delete $record->{issn};
    }

    if ( $record->{e_issn} !~ / \d{4} -? \d{3}[\dxX] /xsm ) {
        delete $record->{e_issn};
    }

    return $class->SUPER::clean_data($record);
}

## preprocess_file - Join the multi-line style of title list into one title list
##                   write a temp file and open it.

sub preprocess_file {
    my ( $class, $IN ) = @_;

    use File::Temp;

    my ( $fh, $filename ) = File::Temp::tempfile();

    # Grab header row

    my $header    = <$IN>;
    my @in_header = split /\t/, $header;

    # Build column map

    my %columns;
    foreach my $x ( 0 .. $#in_header ) {
        $columns{ $in_header[$x] } = $x;
    }

    my %data;

    while ( my $line = <$IN> ) {

        my @fields = split /\t/, $line;

        my $journal_id = $fields[ $columns{'JOURNAL_ID'} ];
        my $title      = $fields[ $columns{'TITLE'} ];
        my $year       = $fields[ $columns{'YEAR'} ];
        my $issn       = $fields[ $columns{'OFFLINE_ISSN'} ];
        my $e_issn     = $fields[ $columns{'ONLINE_ISSN'} ];
        my $volumes    = $fields[ $columns{'VOLUMES'} ];

        next if $year !~ / \d{4} /xsm;

        if ( $volumes =~ / V(\d+) /xsm ) {
            $volumes = $1;
        }
        else {
            next;
        }

        if ( !exists( $data{$journal_id} ) ) {
            $data{$journal_id}->{journal_id}    = $journal_id;
            $data{$journal_id}->{title}         = $title;
            $data{$journal_id}->{issn}          = $issn;
            $data{$journal_id}->{e_issn}        = $e_issn;
            $data{$journal_id}->{ft_start_date} = $year;
            $data{$journal_id}->{ft_end_date}   = $year;
            $data{$journal_id}->{vol_ft_start}  = $volumes;
            $data{$journal_id}->{vol_ft_end}    = $volumes;
        }
        else {
            if ( $year < $data{$journal_id}->{ft_start_date} ) {
                $data{$journal_id}->{ft_start_date} = $year;
            }

            if ( $year > $data{$journal_id}->{ft_end_date} ) {
                $data{$journal_id}->{ft_end_date} = $year;
            }

            if ( $volumes < $data{$journal_id}->{vol_ft_start} ) {
                $data{$journal_id}->{vol_ft_start} = $volumes;
            }

            if ( $volumes > $data{$journal_id}->{vol_ft_end} ) {
                $data{$journal_id}->{vol_ft_end} = $volumes;
            }
        }
    }

    print $fh (
        join "\t", qw(
            title
            issn
            e_issn
            ft_start_date
            ft_end_date
            vol_ft_start
            vol_ft_end
            db_identifier
        )
    );
    print $fh "\n";

    foreach my $rec ( values(%data) ) {

        print $fh (
            join "\t", (
                $rec->{title},
                $rec->{issn},
                $rec->{e_issn},
                $rec->{ft_start_date},
                $rec->{ft_end_date},
                $rec->{vol_ft_start},
                $rec->{vol_ft_end},
                $rec->{journal_id}
            )
        );
        print $fh "\n";

    }

    close *$IN;
    seek *$fh, 0, 0;

    return $fh;
}

## -------------------------------------------------------------------------------------------

## can_get* - Control whether or not an attempt to create a link is built.  This is run
## before the database is searched for possible title matches, so catching requests without
## enough data, etc. early (here) cuts down on database hits

sub can_getTOC {
    my ( $class, $request ) = @_;

    return 0
        if is_empty_string( $request->volume )
        || is_empty_string( $request->issue );

    return $class->SUPER::can_getTOC($request);
}

# --------------------------------------------------------------------------------------------

## build_link* - Builds a link to a service.  Should return an array reference containing
## Result objects with urls and title list records (if applicable).
##

sub build_linkTOC {
    my ( $class, $schema, $records, $resource, $site, $request ) = @_;

    defined($records) && scalar(@$records) > 0
        or return [];
    defined($resource)
        or
        CUFTS::Exception::App->throw('No resource defined in build_linkTOC');
    defined($site)
        or CUFTS::Exception::App->throw('No site defined in build_linkTOC');
    defined($request)
        or
        CUFTS::Exception::App->throw('No request defined in build_linkTOC');

    my @results;

    foreach my $record (@$records) {

        my $volume = $request->volume;
        my $issue  = $request->issue;
        $volume =~ tr/0-9//cd;
        $issue  =~ tr/0-9//cd;

        my $url = $url_base . 'issue_' . prepTitle( $record->title );
        $url .= '/Vol'
            . sprintf( "%02u", $volume ) . 'No'
            . sprintf( "%02u", $issue );

        my $result = new CUFTS::Result($url);
        $result->record($record);

        push @results, $result;
    }

    return \@results;
}

#### ROUTINE TO FORMAT JOURNAL TITLE FOR TABLE OF CONTENTS LINK
sub prepTitle {

    my $title = shift;

    my $preppedTitle = "";

    # remove spaces and upper case first letter of each word in title
    my @words = split( /\s/, $title );
    foreach my $word (@words) {
        $preppedTitle .= ucfirst($word);
    }
    $preppedTitle =~ s/,//g;
    $preppedTitle = uri_escape($preppedTitle);

    return $preppedTitle;
}

sub build_linkJournal {
    my ( $class, $schema, $records, $resource, $site, $request ) = @_;

    defined($records) && scalar(@$records) > 0
        or return [];
    defined($resource)
        or CUFTS::Exception::App->throw(
        'No resource defined in build_linkJournal');
    defined($site)
        or
        CUFTS::Exception::App->throw('No site defined in build_linkJournal');
    defined($request)
        or CUFTS::Exception::App->throw(
        'No request defined in build_linkJournal');

    my @results;

    foreach my $record (@$records) {

        next if is_empty_string( $record->db_identifier );

        my $url = $url_base . 'jid_' . $record->db_identifier;

        my $result = new CUFTS::Result($url);
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
        or CUFTS::Exception::App->throw(
        'No resource defined in build_linkDatabase');
    defined($site)
        or
        CUFTS::Exception::App->throw('No site defined in build_linkDatabase');
    defined($request)
        or CUFTS::Exception::App->throw(
        'No request defined in build_linkDatabase');

    my @results;

    foreach my $record (@$records) {

        my $url = $resource->database_url || 'http://www.journals.cup.org/';

        my $result = new CUFTS::Result($url);
        $result->record($record);

        push @results, $result;
    }

    return \@results;
}

1;
