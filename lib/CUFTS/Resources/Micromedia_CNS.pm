## CUFTS::Resources::Micromedia_CNS (for Canadian NewStand)
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

package CUFTS::Resources::Micromedia_CNS;

use base qw(CUFTS::Resources::Base::Journals);

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
            ft_start_date
            ft_end_date
        )
    ];
}

sub overridable_resource_details {
    return undef;
}

sub resource_details_help {
    return {};
}

sub title_list_field_map {
    return {
        'title'         => 'title',
        'issn'          => 'issn',
        'ft_start_date' => 'ft_start_date',
        'ft_end_date'   => 'ft_end_date',
    };
}


sub can_getFulltext {
    my ( $class, $request ) = @_;

    return 0 if is_empty_string( $request->atitle );

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

        my @params = ();

        push( @params, 'jtitle=' . $record->title   );
        push( @params, 'atitle=' . $request->atitle );

        defined( $request->volume )
            and push @params, 'volume=' . $request->volume;
        defined( $request->issue )
            and push @params, 'issue='  . $request->issue;
        defined( $request->date )
            and push @params, 'date='   . $request->date;
        defined( $request->spage )
            and push @params, 'spage='  . $request->spage;

        my $url = 'http://gateway.proquest.com/openurl?ctx_ver=Z39.88-2003';
        $url .= '&res_id=xri:pqd&rft_val_fmt=ori:fmt:kev:mtx:journal&genre=article&';
        $url .= join '&', @params;

        my $result = new CUFTS::Result($url);
        $result->record($record);

        push @results, $result;
    }

    return \@results;
}

sub can_getTOC {
    my ( $class, $request ) = @_;

    return 0 if is_empty_string( $request->date );

    return $class->SUPER::can_getTOC($request);
}

# use title search with date rather than issn since many issn links don't seem to work with this list
sub build_linkTOC {
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

        my @params = ();
        push( @params, 'jtitle=' . $record->title );

        defined( $request->volume )
            and push @params, 'volume=' . $request->volume;
        defined( $request->issue )
            and push @params, 'issue=' . $request->issue;
        defined( $request->date )
            and push @params, 'date=' . $request->date;

        my $url = 'http://gateway.proquest.com/openurl?ctx_ver=Z39.88-2003';
        $url .= '&res_id=xri:pqd&rft_val_fmt=ori:fmt:kev:mtx:journal&';
        $url .= join '&', @params;

        my $result = new CUFTS::Result($url);
        $result->record($record);

        push @results, $result;
    }

    return \@results;
}

# found too many problems with ISSN searches coming up blank for titles in the list so
# use title search link (takes longer but has higher success rate)
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

        my $url = 'http://gateway.proquest.com/openurl?ctx_ver=Z39.88-2003';
        $url .= '&res_id=xri:pqd&rft_val_fmt=ori:fmt:kev:mtx:journal';
        $url .= '&jtitle=' . $record->title . '&svc_id=xri:pqil:context=title';

        my $result = new CUFTS::Result($url);
        $result->record($record);

        push @results, $result;
    }

    return \@results;
}

1;
