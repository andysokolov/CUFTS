## CUFTS::Resources::Micromedia (General)
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

package CUFTS::Resources::Micromedia;

use base qw(CUFTS::Resources::Base::Journals);

use CUFTS::Exceptions;
use CUFTS::Util::Simple;

use strict;

sub services {
    return [ qw( fulltext journal database ) ];
}

my $base_url = 'http://openurl.proquest.com/in?service=pq&';

sub title_list_fields {
    return [
        qw(
            id
            title
            issn
            cit_start_date
            cit_end_date
            ft_start_date
            ft_end_date
        )
    ];
}

sub title_list_field_map {
    return {
        'title'          => 'title',
        'issn'           => 'issn',
        'ft_start_date'  => 'ft_start_date',
        'ft_end_date'    => 'ft_end_date',
        'cit_start_date' => 'cit_start_date',
        'cit_end_date'   => 'cit_end_date'
    };
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
        my $temp_url;

        if (   assert_ne( $request->spage )
            && assert_ne( $request->volume )
            && assert_ne( $record->issn )
            && assert_ne( $request->issue ) )
        {

            $temp_url = $base_url;
        }
        elsif ( assert_ne( $record->title ) && assert_ne( $request->atitle ) )
        {
            $temp_url
                = 'http://gateway.proquest.com/openurl?ctx_ver=Z39.88-2003';
            $temp_url
                .= '&res_id=xri:pqd&rft_val_fmt=ori:fmt:kev:mtx:journal&genre=article&';

            push( @params, 'jtitle=' . $record->title );
            push( @params, 'atitle=' . $request->atitle );
        }
        else { next; }

        defined( $record->issn )
            and push @params, 'issn=' . $record->issn;
        defined( $request->volume )
            and push @params, 'volume=' . $request->volume;
        defined( $request->issue )
            and push @params, 'issue=' . $request->issue;
        defined( $request->date )
            and push @params, 'date=' . $request->date;
        defined( $request->spage )
            and push @params, 'spage=' . $request->spage;

        my $url = $temp_url;
        $url .= join '&', @params;

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
        my @params = ();
        my $temp_url;

        if (   assert_ne( $record->issn )
            && assert_ne( $request->volume )
            && assert_ne( $request->issue ) )
        {
            $temp_url = $base_url;
        }
        elsif ( assert_ne( $record->title ) && assert_ne( $request->date ) ) {
            $temp_url
                = 'http://gateway.proquest.com/openurl?ctx_ver=Z39.88-2003';
            $temp_url
                .= '&res_id=xri:pqd&rft_val_fmt=ori:fmt:kev:mtx:article&';
            push( @params, 'jtitle=' . $record->title );

        }
        else { next; }

        defined( $record->issn )
            and push @params, 'issn=' . $record->issn;
        defined( $request->volume )
            and push @params, 'volume=' . $request->volume;
        defined( $request->issue )
            and push @params, 'issue=' . $request->issue;
        defined( $request->date )
            and push @params, 'date=' . $request->date;

        my $url = $temp_url;
        $url .= join '&', @params;

        my $result = new CUFTS::Result($url);
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
        next unless assert_ne( $record->issn );

        my $result = new CUFTS::Result( $base_url . 'issn=' . $record->issn );
        $result->record($record);

        push @results, $result;
    }

    return \@results;
}

1;
