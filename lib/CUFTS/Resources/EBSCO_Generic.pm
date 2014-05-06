## CUFTS::Resources::EBSCO_Generic
##
## Copyright Todd Holbrook - Simon Fraser University (2005)
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

# Generic module for EBSCO hosted databases created by other sources.  This
# is intended as a base module and not to be used directly.

package CUFTS::Resources::EBSCO_Generic;

use strict;

use base qw(CUFTS::Resources::Base::Journals);

use URI::Escape;
use CUFTS::Exceptions;
use CUFTS::Util::Simple;

sub services {
    return [ qw( fulltext journal database ) ];
}

sub _search_fields {
    return {
        issn   => 'is',
        title  => 'jn',
        spage  => 'st',
        volume => 'vi',
        issue  => 'ip',
        atitle => 'ti',
    };
}

sub _build_journal_search_field {
    my ( $class, $title, $issn ) = @_;

    my $search_fields = $class->_search_fields();

    if ( !not_empty_string($issn) ) {
        return $search_fields->{issn} . '=' . $issn;
    }

    return $search_fields->{title} . '=' . uri_escape($title);
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
            embargo_months
            publisher
        )
    ];
}

sub title_list_field_map {
    return {
        'Publication Name'                  => 'title',
        'ISSN'                              => 'issn',
        'ISSN/ISBN'                         => 'issn',
        'ISSN / ISBN'                       => 'issn',
        'Publisher'                         => 'publisher',
        'Full Text Delay (in months)'       => 'embargo_months',
        'Full Text Delay (Months)'          => 'embargo_months',
        'Full Text*'                        => '___Full Text',
        'Full Text**'                       => '___Full Text',
        'Full Text Start'                   => 'ft_start_date',
        'Full Text Stop'                    => 'ft_end_date',
        'Indexing and Abstracting Start'    => 'cit_start_date',
        'Indexing and Abstracting Stop'     => 'cit_end_date',
    };
}

sub skip_record {
    my ( $class, $record ) = @_;

#    return 1 if $record->{'___Source Type'} =~ /book|monograph/i;

    return 0
}

sub clean_data {
    my ( $class, $record ) = @_;

    foreach my $field ( qw( ft_start_date ft_end_date cit_start_date cit_end_date ) ) {
        next if is_empty_string($record->{$field});
        if ( $record->{$field} =~ m{^ (\d{2}) / (\d{2}) / (\d{4}) }xsm ) {
            $record->{$field} = "$3-$1-$2";
        }
    }

    my $fulltext = $record->{'___Full Text'};
    if ( not_empty_string( $fulltext ) ) {

        if ( $fulltext =~ m{^ \s* (\d{1,2}) / (\d{1,2}) / (\d{4}) }xsm ) {
            $record->{ft_start_date} = "$3/$1/$2";
        }
        elsif ( $fulltext =~ m{^ \s* (\d{4}) }xsm ) {
            $record->{ft_start_date} = $1;
        }


        if ( $fulltext =~ m{ to \s+ (\d{1,2}) / (\d{1,2}) / (\d{4}) \s* $}xsm ) {
            $record->{ft_end_date} = "$3/$1/$2";
        }
        elsif ( $fulltext =~ m{ to \s+ (\d{4}) }xsm ) {
            $record->{ft_end_date} = $1;
        }

    }

    if ( defined( $record->{'___Searchable Cited References'} ) ) {

        if ( $record->{'___Searchable Cited References'} =~ m{^ \s* (\d{1,2}) / (\d{1,2}) / (\d{1,4}) }xsm ) {
            $record->{cit_start_date} = "$3/$1/$2";
        }
        elsif ( $record->{'___Searchable Cited References'} =~ m{^ \s* (\d{4}) }xsm ) {
            $record->{cit_start_date} = $1;
        }

    }

    if ( defined( $record->{'___Searchable Cited References'} ) ) {

        if ( $record->{'___Searchable Cited References'} =~ m{ to \s+ (\d{1,2}) / (\d{1,2}) / (\d{4}) }xsm ) {
            $record->{cit_end_date} = "$3/$1/$2";
        }
        elsif ( $record->{'___Searchable Cited References'} =~ m{ to \s+ (\d{4}) }xsm ) {
            $record->{cit_end_date} = $1;
        }

    }

    if ( defined( $record->{embargo_months} ) ) {
        $record->{embargo_months} = int( $record->{embargo_months} + 0.99 );
    }

    $record->{title}     = trim_string($record->{title},     '"');
    $record->{publisher} = trim_string($record->{publisher}, '"');

    # Remove trailing *

    $record->{title} =~ s/\*$//;

    # HTML decoding of the title

    $record->{title} = HTML::Entities::decode_entities( $record->{title} );

    return $class->SUPER::clean_data($record);
}

sub global_resource_details {
    my ($class) = @_;
    return [
        @{ $class->SUPER::global_resource_details },
        qw(
            resource_identifier
        )
    ];
}

sub local_resource_details {
    my ($class) = @_;
    return [
        @{ $class->SUPER::local_resource_details },
        qw(
            auth_name
        )
    ];
}

sub help_template {
    return 'help/EBSCO';
}

sub resource_details_help {
    my ($class) = @_;

    my $help_hash = $class->SUPER::resource_details_help;

    $help_hash->{'resource_identifier'}
        = "This is a three character code that EBSCO uses to uniquely identify some databases.\n\nExample: AFH";
    $help_hash->{'auth_name'}
        = "This is a code used by EBSCO to identify your site.  It is passed to their Article Matcher system in order to determine which databases and articles you should have access to.\n\nExample: s9612765.main.web";

    return $help_hash;
}

sub can_getTOC {
    my ( $class, $request ) = @_;

    return 0
        if is_empty_string( $request->volume );

    return $class->SUPER::can_getTOC($request);

}

sub can_getFulltext {
    my ( $class, $request ) = @_;

    return 0
        if is_empty_string( $request->spage  )
        && is_empty_string( $request->atitle );

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
        or CUFTS::Exception::App->throw('No request defined in build_Fulltext');

    my @results;

    my $search_fields = $class->_search_fields;

    foreach my $record (@$records) {

        my $db = $resource->resource_identifier;
        next if is_empty_string($db);
        $db = lc($db);

        my $url = "http://search.ebscohost.com/direct.asp?db=${db}&";

        $url .= $class->_build_journal_search_field( $record->title, $record->issn );

        ##
        ## Article titles containing two character words are screwing up the search due to
        ## index terms being two character codes, so try spage search if possible.
        ##

        if ( $request->spage ) {
            $url .= "+AND+$search_fields->{'volume'}+" . $request->volume;
            $url .= "+AND+$search_fields->{'issue'}+"  . $request->issue;
            $url .= "+AND+$search_fields->{'spage'}+"  . $request->spage;
        }
        else {
            my $atitle = $request->atitle;

            $atitle =~ s/\?//g;    # EBSCO chokes on '?' as it's a wildcard
            $atitle = uri_escape($atitle);
            $atitle =~ s/\-/%2D/g;

            $url .= "+AND+$search_fields->{'atitle'}+" . $atitle;
        }

        my $result = new CUFTS::Result($url);
        $result->record($record);

        push @results, $result;
    }

    return \@results;
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

    my %search_fields = %{ $class->_search_fields };

    foreach my $record (@$records) {

        my $db = $resource->resource_identifier;
        next if is_empty_string($db);
        $db = lc($db);

        my $url = "http://search.ebscohost.com/direct.asp?db=${db}&";

        $url .= $class->_build_journal_search_field( $record->title, $record->issn );

        $url .= "+AND+$search_fields{'volume'}+" . $request->volume;

        if ( not_empty_string( $request->issue ) ) {
            $url .= "+AND+$search_fields{'issue'}+" . $request->issue;
        }

        my $result = new CUFTS::Result;
        $result->url($url);
        $result->record($record);

        push @results, $result;
    }

    return \@results;
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

    my %search_fields = %{ $class->_search_fields };

    foreach my $record (@$records) {

        my $db = $resource->resource_identifier;
        next if is_empty_string($db);
        $db = lc($db);

        my $url = "http://search.ebscohost.com/direct.asp?db=${db}&scope=site&";

        $url .= $class->_build_journal_search_field( $record->title, $record->issn );

        my $result = new CUFTS::Result;
        $result->url($url);
        $result->record($record);

        push @results, $result;
    }

    return \@results;
}

sub build_linkDatabase {
    my ( $class, $schema, $records, $resource, $site, $request ) = @_;

    my $db = $resource->resource_identifier;
    return [] if is_empty_string($db);

    my @results;

    foreach my $record (@$records) {
        my $url = $resource->database_url
               || "http://search.ebscohost.com/login.asp?profile=web&defaultdb=$db";

        my $result = new CUFTS::Result($url);
        $result->record($record);

        push @results, $result;
    }

    return \@results;
}

1;
