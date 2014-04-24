## CUFTS::Resources::Gale_II
##
## Copyright Michelle Gauthier - Simon Fraser University (2003)
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

package CUFTS::Resources::Gale_II;

use base qw(CUFTS::Resources::Base::Journals CUFTS::Resources::Base::DateTimeNatural);

use CUFTS::Exceptions;
use CUFTS::Util::Simple;
use URI::Escape;

use strict;

## title_list_fields - Controls what fields get displayed and loaded from
## title lists.
##

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
        )
    ];
}

## title_list_field_map - Hash ref mapping fields from the raw title lists to
## internal field names
##

sub title_list_field_map {
    return {
        'Journal Name'          => 'title',
        'ISSN'                  => 'issn',
        'Embargo (Days)'        => 'embargo_days',
        'Full-text Exceptions'  => 'cjdb_note',
    };
}

sub overridable_resource_details {
        my ($class) = @_;

        my $details = $class->SUPER::overridable_resource_details();
        push @$details, 'url_base';

        return $details;
}

sub skip_record {
    my ( $class, $record ) = @_;

    return is_empty_string( $record->{title} )
           || $record->{title} =~ /^\s*"?--/;
}


sub clean_data {
    my ( $class, $record ) = @_;

    $record->{cit_start_date} = $class->parse_start_date( $record->{'___Index Start'} );
    $record->{cit_end_date}   = $class->parse_end_date( $record->{'___Index End'} );

    $record->{ft_start_date}  = $class->parse_start_date( map { $record->{$_} } ( '___Full-text Start', '___Full-Text Start', '___Image Start' ) );
    $record->{ft_end_date}    = $class->parse_start_date( map { $record->{$_} } ( '___Full-text End', '___Full-Text End', '___Image End' ) );

    if ( hascontent($record->{cjdb_note}) ) {
        $record->{cjdb_note} = 'Full-text exceptions: ' . trim_string($record->{cjdb_note}, '"');
    }

    # Gale can't seem to keep their columns consistent, so try an alternative
    # NOTE: do not enable this.  Gale_III does exact title searching and Gale's interface chokes if you don't include the end parts like "(US)"
    #    $record->{title} =~ s/\s*\(.+?\)\s*$//g;

    return $class->SUPER::clean_data($record);
}

## global_resource_details - Controls which details are displayed on the global
## resource pages
##

sub global_resource_details {
    my ($class) = @_;
    return [
        @{ $class->SUPER::global_resource_details },
        qw(
            resource_identifier
            url_base
        )
    ];
}

## local_resource_details - Controls which details are displayed on the local
## resource pages
##

sub local_resource_details {
    my ($class) = @_;
    return [
        @{ $class->SUPER::local_resource_details },
        qw(
            url_base
            auth_name
            proxy_suffix
        )
    ];
}

## resource_details_help - A hash ref containing the hoverover help for each of the
## local resource details
##

sub resource_details_help {
    my ($class) = @_;

    my $help_hash = $class->SUPER::resource_details_help;
    $help_hash->{'resource_identifier'} = 'Unique code defined by Gale for each database or resource.';
    $help_hash->{'url_base'}            = 'Base URL for linking to resource.';
    $help_hash->{'auth_name'}           = 'Location ID assigned by Gale. Used in construction of URL.';
    return $help_hash;
}

## -------------------------------------------------------------------------------------------

## build_link* - Builds a link to a service.  Should return an array reference containing
## Result objects with urls and title list records (if applicable).
##

sub build_linkDatabase {
    my ( $class, $schema, $records, $resource, $site, $request ) = @_;

    my @results;

    foreach my $record (@$records) {

        my $url = $resource->database_url;
        if ( is_empty_string($url) ) {
            $url = $resource->url_base;
            if ( $resource->auth_name ) {
                $url .= $resource->auth_name;
            }

            if ( $resource->resource_identifier ) {
                if ( $url =~ /IOURL/ ) {
                    $url .= '?prod=' . $resource->resource_identifier;
                } else {
                    $url .= '?db=' . $resource->resource_identifier;
                }
            }
        }
        if ( is_empty_string($url) ) {
            return [];
        }

        $url .= __add_proxy_suffix($url, $resource->proxy_suffix);
        my $result = new CUFTS::Result($url);
        $result->record($record);

        push @results, $result;
    }

    return \@results;
}

sub build_linkJournal {
    my ( $class, $schema, $records, $resource, $site, $request ) = @_;

    my @results;

    foreach my $record (@$records) {

        my $url = $resource->url_base;
        if ( is_empty_string($url) ) {
            $url = $resource->database_url;
        }
        if ( is_empty_string($url) ) {
            return [];
        }

        my $escaped_title = uri_escape($record->title);
        my $resource_identifier = $resource->resource_identifier;

        # Try first style of linking:
        # http://infotrac.galegroup.com.darius/itw/infomark/1/1/1/purl=rc18%5fSP09%5F0%5F%5Fjn+%22Computers+in+Libraries%22


        if ( $url =~ /purl=rc1/ ) {
            $url .= "\%22${escaped_title}\%22";
        }

        # Second link style
        # http://find.galegroup.com/itx/publicationSearch.do?dblist=&serQuery=Locale%28en%2C%2C%29%3AFQE%3D%28JX%2CNone%2C24%29%22{title}%22%24&inPS=true&type=getIssues&searchTerm=&prodId={resource_identifier}&currentPosition=0
        # may need an authname: &userGroupName=leth89164

        elsif ( $url =~ /\{title\}/ ) {
            $url =~ s/\{title\}/$escaped_title/e;
            $url =~ s/\{resource_identifier\}/$resource_identifier/e;
        }

        # Original, should have an example here.
        else {
            if ( $resource->resource_identifier ) {
                if ( $url =~ /IOURL/ ) {
                    $url .= '?prod=' . $resource_identifier;
                } else {
                    $url .= '?db=' . $resource_identifier;
                }
            }

            $url .= "&title=${escaped_title}";
        }

        if ( $resource->auth_name ) {
            $url .= $resource->auth_name;
        }

        $url .= __add_proxy_suffix($url, $resource->proxy_suffix);

        my $result = new CUFTS::Result($url);
        $result->record($record);

        push @results, $result;
    }

    return \@results;
}


sub can_getFulltext {
    return 0;
}

sub can_getJournal {
    return 1;
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
