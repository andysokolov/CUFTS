## CUFTS::Resources::Gale3_III
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

package CUFTS::Resources::Gale_III;

use base qw( CUFTS::Resources::Base::Journals CUFTS::Resources::Base::DateTimeNatural );

use CUFTS::Exceptions;
use CUFTS::Util::Simple;
use String::Util qw(hascontent trim);

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
            ft_start_date
            ft_end_date
            cit_start_date
            cit_end_date
            embargo_days
            cjdb_note
        )
    ];
}

## title_list_field_map - Hash ref mapping fields from the raw title lists to
## internal field names
##

sub title_list_field_map {
    return {
        'Journal Name'          => 'title',
        'Publication Name'      => 'title',
        'ISSN'                  => 'issn',
        'Embargo (Days)'        => 'embargo_days',
        'Publisher'             => 'publisher',
        'Full-text Exceptions'  => 'cjdb_note',
    };
}

sub overridable_resource_details {
        my ($class) = @_;

        my $details = $class->SUPER::overridable_resource_details();
        push @$details, 'url_base';

        return $details;
}

sub global_resource_details {
    my ($class) = @_;
    return [
        @{ $class->SUPER::global_resource_details },
        qw(
            url_base
        )
    ];
}

sub local_resource_details {
    my ($class) = @_;
    return [
        @{ $class->SUPER::local_resource_details },
        qw(
            url_base
            proxy_suffix
        )
    ];
}

sub resource_details_help {
    return { $_[0]->SUPER::resource_details_help,
        'url_base' =>
            "Base URL for faking searches.\nExample:\nhttp://infotrac.galegroup.com/itw/infomark/1/1/1/purl=rc11_CPI_0_",
    };
}

sub skip_record {
    my ( $class, $record ) = @_;

    return is_empty_string( $record->{title} )
           || $record->{title} =~ /^\s*"?--/;
}

sub clean_data {
    my ( $class, $record ) = @_;

    $record->{cit_start_date} = $class->parse_start_date( map { $record->{$_} } ( '___Index Start', '___Index Start Date' ) );
    $record->{cit_end_date}   = $class->parse_end_date(   map { $record->{$_} } ( '___Index End',   '___Index End Date' ) );

    $record->{ft_start_date}  = $class->parse_start_date( map { $record->{$_} } ( '___Full-text Start', '___Full-Text Start', '___Full-text Start Date', '___Image Start', '___Image Start Date' ) );
    $record->{ft_end_date}    = $class->parse_end_date(   map { $record->{$_} } ( '___Full-text End',   '___Full-Text End',   '___Full-text End Date',   '___Image End',   '___Image End Date' ) );

    if ( hascontent($record->{cjdb_note}) ) {
        $record->{cjdb_note} = 'Full-text exceptions: ' . trim_string($record->{cjdb_note}, '"');
    }

    # Gale can't seem to keep their columns consistent, so try an alternative
    # NOTE: do not enable this.  Gale_III does exact title searching and Gale's interface chokes if you don't include the end parts like "(US)"
#    $record->{title} =~ s/\s*\(.+?\)\s*$//g;

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

        my $url = $resource->url_base;
        $url =~ s/rc11/rc18/;  # Makes link go to journal page rather than results list

        my $title = $record->title;
        $title =~ tr/ /+/;
        $title = uri_escape($title);
        $url .= "_jn+%22$title%22";

        $url .= __add_proxy_suffix($url, $resource->proxy_suffix);

        my $result = new CUFTS::Result($url);
        $result->record($record);
        push @results, $result;
    }

    return \@results;
}

# Fakes a search like this:
# http://infotrac.galegroup.com/itw/infomark/1/1/1/purl=rc11_LT_0_sn_0891-6330_AND_vo_16_AND_iu_4

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

    defined( $resource->url_base )
        or CUFTS::Exception::App->throw('No url_base defined for resource: ' . $resource->name);

    my @results;
    foreach my $record (@$records) {
        next if is_empty_string( $request->volume )
             && is_empty_string( $request->issue  );

        my $url = $resource->url_base;

        if ( is_empty_string($record->issn) ) {
            my $title = $record->title;
            $title =~ tr/ /+/;
            $title = uri_escape($title);
            $url .= "ke_jn+%22$title%22";
        }
        else {
            my $issn = $record->issn;
            substr( $issn, 4, 0 ) = '-';
            $url .= "ke_sn+$issn";
        }

        if ( not_empty_string($request->volume) ) {
            $url .= '+AND+vo+' . $request->volume;
        }

        if ( not_empty_string($request->issue) ) {
            $url .= '+AND+iu+' . $request->issue;
        }

        $url .= __add_proxy_suffix($url, $resource->proxy_suffix);

        my $result = new CUFTS::Result($url);
        $result->record($record);
        push @results, $result;
    }

    return \@results;
}

# Fakes a search like this:
# http://infotrac.galegroup.com/itw/infomark/1/1/1/purl=rc11_LT_0_sn_0891-6330_AND_vo_16_AND_iu_4

sub build_linkFulltext {
    my ( $class, $schema, $records, $resource, $site, $request ) = @_;

    defined($records) && scalar(@$records) > 0
        or return [];
    defined($resource)
        or CUFTS::Exception::App->throw('No resource defined in build_linkTOC');
    defined($site)
        or CUFTS::Exception::App->throw('No site defined in build_linkTOC');
    defined($request)
        or CUFTS::Exception::App->throw('No request defined in build_linkTOC');

    defined( $resource->url_base )
        or CUFTS::Exception::App->throw('No url_base defined for resource: ' . $resource->name);

    my @results;
    foreach my $record (@$records) {
        next if is_empty_string( $request->volume )
             && is_empty_string( $request->issue  );

        my $url = $resource->url_base;
        next if is_empty_string( $url );

        if ( is_empty_string($record->issn) ) {
            my $title = $record->title;
            $title =~ tr/ /+/;
            $title = uri_escape($title);
            $url .= "ke_jn+%22$title%22";
        }
        else {
            my $issn = $record->issn;
            substr( $issn, 4, 0 ) = '-';
            $url .= "ke_sn+$issn";
        }

        if ( not_empty_string($request->volume) ) {
            $url .= '+AND+vo+' . $request->volume;
        }

        if ( not_empty_string($request->issue) ) {
            $url .= '+AND+iu+' . $request->issue;
        }

        if ( not_empty_string($request->spage) ) {
            $url .= '+AND+sp+' . $request->spage;
        }

#        if ( not_empty_string($request->atitle) ) {
#            $url .= '+AND+ti+' . $request->atitle;
#        }

        $url .= __add_proxy_suffix($url, $resource->proxy_suffix);

        my $result = new CUFTS::Result($url);
        $result->record($record);
        push @results, $result;
    }

    return \@results;
}

sub __add_proxy_suffix {
    my ( $url, $suffix ) = @_;

    if ( not_empty_string( $suffix ) ) {
        # if the URL has a "?" in it already, then convert a leading ? from the suffix into a &

        if ( $url =~ /\?/ ) {
            $suffix =~ s/^\?/&/;
        }
        return $suffix;
    }

    return '';
}

1;
