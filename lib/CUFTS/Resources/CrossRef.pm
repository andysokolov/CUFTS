## CUFTS::Resources::CrossRef
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

package CUFTS::Resources::CrossRef;

use base qw(CUFTS::Resources);

use CUFTS::Exceptions;
use CUFTS::Util::Simple;
use CUFTS::DB::SearchCache;

use LWP::UserAgent;
use HTTP::Request::Common;

use URI::Escape qw(uri_escape);
use String::Util qw(hascontent);
use XML::LibXML;

use Data::Dumper;


use strict;

sub has_title_list { return 0; }

sub local_resource_details       { return [ 'auth_name', 'auth_passwd' ] }
sub global_resource_details      { return [ 'auth_name', 'auth_passwd' ] }
sub overridable_resource_details { return [ 'auth_name', 'auth_passwd' ] }

sub help_template { return undef }

sub resource_details_help {
    return {
        auth_name   => 'Login name provided by CrossRef.',
        auth_passwd => 'Password provided by CrossRef.',
    };
}

sub get_records {
    my ( $class, $resource, $site, $request ) = @_;

    if ( !hascontent( $resource->auth_name ) ) {
        CUFTS::Exception::App->throw('No auth_name defined for CrossRef lookups.');
    }
    if ( !hascontent( $resource->auth_passwd ) ) {
        CUFTS::Exception::App->throw('No auth_passwd defined for CrossRef lookups.');
    }

    my $year = '';
    if ( defined( $request->date ) && $request->date =~ /^(\d{4})/ ) {
        $year = $1;
    }

    my ( $qdata, $qtype, $cache_query );

    if ( hascontent( $request->doi ) ) {
        $cache_query = 'http://www.crossref.org/openurl/?noredirect=true&id=' . uri_escape($request->doi);
    }
    elsif ( hascontent( $request->issn ) || hascontent( $request->eissn ) || hascontent( $request->title ) ) {
        $cache_query = 'http://www.crossref.org/openurl/?noredirect=true';

        if ( hascontent($request->issn) ) {
            $cache_query .= '&issn=' . uri_escape($request->issn);
        }
        if ( hascontent($request->eissn) ) {
            $cache_query .= '&eissn=' . uri_escape($request->eissn);
        }
        if ( hascontent($request->title) ) {
            $cache_query .= '&title=' . uri_escape($request->title);
        }
        if ( hascontent($request->volume) ) {
            $cache_query .= '&volume=' . uri_escape($request->volume);
        }
        if ( hascontent($request->issue) ) {
            $cache_query .= '&issue=' . uri_escape($request->issue);
        }
        if ( hascontent($request->spage) ) {
            $cache_query .= '&spage=' . uri_escape($request->spage);
        }
        if ( hascontent($year) ) {
            $cache_query .= '&date=' . uri_escape($year);
        }
    }
    else {
        return undef;
    }

    # Check the cache

    my $cache_data = CUFTS::DB::SearchCache->search(
        type    => 'crossref',
        'query' => $cache_query,
    )->first;

    if ( !defined($cache_data) ) {

        # Add username/password to OpenURL

        my $openurl = $cache_query . '&pid=' . uri_escape($resource->auth_name . ':' . $resource->auth_passwd);

        # Lookup metadata

        my $start_time = time;

        my $ua = LWP::UserAgent->new( 'timeout' => 20 );
        my $response = $ua->request( GET $openurl );

        $response->is_success or return undef;
        my $xml  = trim_string( $response->content );

        $cache_data = CUFTS::DB::SearchCache->create(
            {   type   => 'crossref',
                query  => $cache_query,
                result => $xml,
            }
        );
        CUFTS::DB::SearchCache->dbi_commit;
    }

    my $doc = XML::LibXML->load_xml( string => $cache_data->result );
    my $xpc = XML::LibXML::XPathContext->new( $doc->documentElement() );
    $xpc->registerNs('cr', 'http://www.crossref.org/qrschema/2.0');


    my $query = $xpc->findnodes('//cr:query[1]')->shift;
    return undef if !defined($query);

    my $title  = get_text_if_defined( $xpc, '//cr:query[1]/cr:journal_title');
    my $atitle = get_text_if_defined( $xpc, '//cr:query[1]/cr:article_title');
    my $volume = get_text_if_defined( $xpc, '//cr:query[1]/cr:volume');
    my $issue  = get_text_if_defined( $xpc, '//cr:query[1]/cr:issue');
    my $spage  = get_text_if_defined( $xpc, '//cr:query[1]/cr:first_page');
    my $year   = get_text_if_defined( $xpc, '//cr:query[1]/cr:year');

    my $doi    = get_text_if_defined( $xpc, '//cr:query[1]/cr:doi[@type=\'journal_article\']');
    my $issn   = get_text_if_defined( $xpc, '//cr:query[1]/cr:doi[@type=\'print\']');
    my $eissn  = get_text_if_defined( $xpc, '//cr:query[1]/cr:doi[@type=\'electronic\']');
    
    !hascontent( $request->doi ) && hascontent($doi)
        and $request->doi($doi);

    # !hascontent( $request->aulast ) && hascontent($aulast)
    #     and $request->aulast($aulast);

    !hascontent( $request->title ) && hascontent($title)
        and $request->title($title);

    !hascontent( $request->atitle ) && hascontent($atitle)
        and $request->atitle($atitle);

    if ( !hascontent( $request->issn ) && hascontent($issn) ) {
        $issn =~ /^([\dxX]{8})/
            and $request->issn($1);
    }

    if ( !hascontent( $request->eissn ) && hascontent($eissn) ) {
        $eissn =~ /^([\dxX]{8})/
            and $request->eissn($1);
    }

    !hascontent( $request->volume ) && hascontent($volume)
        and $request->volume($volume);

    !hascontent( $request->issue ) && hascontent($issue)
        and $request->issue($issue);

    !hascontent( $request->spage ) && hascontent($spage)
        and $request->spage($spage);

    return undef;
}

sub can_getMetadata {
    my ( $class, $request ) = @_;

    hascontent( $request->issn ) || hascontent( $request->eissn )
        and return 1;

    hascontent( $request->title )
        and return 1;

    hascontent( $request->doi )
        and return 1;

    return 0;
}

sub get_text_if_defined {
    my $xpc   = shift;
    my $xpath = shift;

    my $node = $xpc->findnodes($xpath)->shift;
    return defined($node) ? $node->textContent : undef;
}

1;
