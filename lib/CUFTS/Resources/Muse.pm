## CUFTS::Resources::Muse
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
##
## Modified 2004-04-19 by Michelle Gauthier:
##      (1) replaced 'urlbase' title list field with journal_url to reflect changes in JakeFilter module.
##      (2) deleted sub title_list_field_map since default field map inherited from base serves same purpose.
##

package CUFTS::Resources::Muse;

use base qw(CUFTS::Resources::Base::Journals);

use CUFTS::Exceptions;
use CUFTS::Util::Simple;
use URI::Escape qw(uri_escape);

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
            journal_url
            publisher
        )
    ];
}

sub title_list_field_map {
    return {
        'Title'           => 'title',
        'Print ISSN'      => 'issn',
        'Electronic ISSN' => 'e_issn',
        'URL'             => 'journal_url',
        'Publisher'       => 'publisher',
    };
}

sub clean_data {
    my ( $class, $record ) = @_;

    my $start = $record->{'___First Issue in MUSE'};
    my $end   = $record->{'___Final Issue in MUSE'};

    # Some ISSNs are dirty and have extra spaces in them for some reason

    if ( defined( $record->{issn} ) ) {
        $record->{issn} =~ s/[^0-9xX]//g;
    }

    if ( defined( $record->{e_issn} ) ) {
        $record->{e_issn} =~ s/[^0-9xX]//g;
    }

    if ( defined( $start ) && $start =~ / vol\. \s* (\d+) /xsmi ) {
        $record->{vol_ft_start} = $1;
    }

    if ( defined( $start ) && $start =~ / (?: no\. | issue ) \s* (\d+) /xsmi ) {
        $record->{iss_ft_start} = $1;
    }

    if ( defined( $end ) && $end =~ / vol\. \s* (\d+) /xsmi ) {
        $record->{vol_ft_end} = $1;
    }

    if ( defined( $end ) && $end =~ / (?: issue | no\. ) \s* (\d+) /xsmi ) {
        $record->{iss_ft_end} = $1;
    }

    if ( defined( $start ) && $start =~ / \( (.+) \s+ (\d{4}) .* \) /xsm ) {

        my $month = $1;
        $record->{ft_start_date} = $2;
        if ( my $new_month = get_month($month) ) {
            $record->{ft_start_date} .= "-${new_month}";
        }

    }
    elsif ( defined( $start ) && $start =~ / \( (\d{4}) .* \) /xsm ) {
        $record->{ft_start_date} = $1;
    }
    elsif ( defined( $start ) && $start =~ / ( (?: 19|20 ) \d{2} ) /xsm ) {
        $record->{ft_start_date} = $1;
    }

    if ( defined( $end ) && $end =~ / \( (.+) \s+ .* (\d{4}) \) /xsm ) {

        my $month = $1;
        $record->{ft_end_date} = $2;
        if ( my $new_month = get_month($month) ) {
            $record->{'ft_end_date'} .= "-${new_month}";

        }

    }
    elsif ( defined( $end ) && $end =~ / \( .* (\d{4}) \) /xsm ) {
        $record->{ft_end_date} = $1;
    }
    elsif ( defined( $end ) && $end =~ / ( (?: 19|20 ) \d{2} ) /xsm ) {
        $record->{ft_end_date} = $1;
    }

    sub get_month {
        my $month = shift;

        if ( $month =~ /^\s*jan/i )    { return '01' }
        if ( $month =~ /^\s*feb/i )    { return '02' }
        if ( $month =~ /^\s*mar/i )    { return '03' }
        if ( $month =~ /^\s*apr/i )    { return '04' }
        if ( $month =~ /^\s*may/i )    { return '05' }
        if ( $month =~ /^\s*jun/i )    { return '06' }
        if ( $month =~ /^\s*jul/i )    { return '07' }
        if ( $month =~ /^\s*aug/i )    { return '08' }
        if ( $month =~ /^\s*sep/i )    { return '09' }
        if ( $month =~ /^\s*oct/i )    { return '10' }
        if ( $month =~ /^\s*nov/i )    { return '11' }
        if ( $month =~ /^\s*dec/i )    { return '12' }
        if ( $month =~ /^\s*spring/i ) { return '01' }
        if ( $month =~ /^\s*summer/i ) { return '03' }
        if ( $month =~ /^\s*fall/i )   { return '06' }
        if ( $month =~ /^\s*winter/i ) { return '09' }
    }

    return $class->SUPER::clean_data($record);
}

# ----------------------------------------------------------------------------------------------

sub can_getTOC {
    my ( $class, $request ) = @_;

    return 0 if is_empty_string($request->volume);
    return 0 if is_empty_string($request->issue);

    return 1;
}

sub build_linkTOC {
    my ( $class, $schema, $records, $resource, $site, $request ) = @_;

    defined($records) && scalar(@$records) > 0
        or return [];
    defined($resource)
        or CUFTS::Exception::App->throw('No resource defined in build_linkTOC');
    defined($site)
        or CUFTS::Exception::App->throw('No site defined in build_linkTOC');
    defined($request)
        or CUFTS::Exception::App->throw('No request defined in build_linkTOC');

    my @results;

    foreach my $record (@$records) {
        my $url = $class->_build_openurl( $record, $resource, $request );
        next if !defined($url);

        my $result = new CUFTS::Result($url);
        $result->record($record);

        push @results, $result;
    }

    return \@results;
}

sub can_getFulltext {
    my ( $class, $request ) = @_;

    return 0 if is_empty_string($request->volume);
    return 0 if is_empty_string($request->issue);
    return 0 if is_empty_string($request->spage);

    return 1;
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
        my $url = $class->_build_openurl( $record, $resource, $request );
        next if !defined($url);

        $url .= "&spage=" . $request->spage;

        my $result = new CUFTS::Result($url);
        $result->record($record);

        push @results, $result;
    }

    return \@results;
}


sub _build_openurl {
    my ( $class, $record, $resource, $request ) = @_;

    my $url = "http://muse.jhu.edu/cgi-bin/resolve_openurl.cgi?genre=article";

    $url .= "&title=" . uri_escape($record->title);

    if ( not_empty_string($record->issn) ) {
        $url .= "&issn=" . $record->issn;
    }
    elsif ( not_empty_string($record->e_issn) ) {
        $url .= "&issn=" . $record->e_issn;
    }

    if ( not_empty_string($request->volume) ) {
        $url .= "&volume=" . $request->volume;
    }

    if ( not_empty_string($request->issue) ) {
        $url .= "&issue=" . $request->issue;
    }

    return $url;
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
