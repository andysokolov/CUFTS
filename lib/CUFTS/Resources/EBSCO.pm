## CUFTS::Resources::EBSCO
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

package CUFTS::Resources::EBSCO;

use base qw(CUFTS::Resources::Base::Journals);

use CUFTS::Exceptions;
use CUFTS::Util::Simple;

use CUFTS::DB::SearchCache;

use LWP::UserAgent;
use HTTP::Request;
use HTML::Entities ();

use strict;

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
            embargo_days
            publisher

            db_identifier
        )
    ];
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
            resource_identifier
        )
    ];
}

sub help_template {
    return 'help/EBSCO';
}

sub resource_details_help {
    my $help_hash = $_[0]->SUPER::resource_details_help;

    $help_hash->{'resource_identifier'} = "This is a three character code that EBSCO uses to uniquely identify each database.\n\nExample: AFH";
    $help_hash->{'auth_name'} = "This is a code used by EBSCO to identify your site.  It is passed to their Article Matcher system in order to determine which databases and articles you should have access to.\n\nExample: s9612765.main.web";

    return $help_hash;
}

sub title_list_field_map {
    return {
        'TITLE'          => 'title',
        'ISSN'           => 'issn',
        'CITATION_START' => 'cit_start_date',
        'CITATION_END'   => 'cit_end_date',
        'FULLTEXT_START' => 'ft_start_date',
        'FULLTEXT_END'   => 'ft_end_date',
        'DB_IDENTIFIER'  => 'db_identifier',
        'URLBASE'        => 'journal_url',
        'PUBLISHER'      => 'publisher',
    };
}

sub clean_data {
    my ( $class, $record ) = @_;
    my @errors;

    if ( defined( $record->{'___EMBARGO'} ) && $record->{'___EMBARGO'} =~ /(\d+)\s+(\w+)/ ) {
            my ( $amount, $period ) = ( $1, $2 );
            if ( $period =~ /^month/ ) {
                $record->{embargo_months} = $amount;
            }
            elsif ( $period =~ /^day/ ) {
                $record->{embargo_days} = $amount;
            }
    }


    # Some EBSCO lists now have MM/DD/YY format for dates

    foreach my $field ( qw( ft_start_date ft_end_date cit_start_date cit_end_date ) ) {
        if ( not_empty_string($record->{$field}) && $record->{$field} =~ m{^ (\d{1,2}) / (\d{2}) / (\d{2}) $}xsm ) {
            my ( $month, $day, $year ) = ( $1, $2, $3 );
            $year += $year < 20 ? 2000 : 1900;
            $record->{$field} = sprintf( '%04i-%02i-%02i', $year, $month, $day );
        }
    }

    # Clear embargo months/days if there's no fulltext start/end dates

    if ( is_empty_string($record->{ft_start_date}) && is_empty_string($record->{ft_end_date}) ) {
            delete $record->{embargo_months};
            delete $record->{embargo_days};
    }

    # HTML decoding of the title

    $record->{title} = HTML::Entities::decode_entities( $record->{title} );

    my $errors = $class->SUPER::clean_data($record);
    push @errors, @$errors if defined($errors);

    # Clear out trailing (...) information in title fields... unless the title starts with a (

#    if ( defined( $record->{'title'} ) && $record->{'title'} !~ /^\(/ ) {
#        $record->{'title'} =~ s/ \s* \( .+? \) \s* $//xsm;
#    }

    return \@errors;
}

sub build_linkFulltext {
    my ( $class, $records, $resource, $site, $request ) = @_;

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
        my $XML     = $class->produce_ebsco_xml( $record, $resource, $site, $request );

        my $text    = $class->check_article_matcher( $XML );
        $text       = $class->preparse_ebsco_fulltext( $text, $record, $resource, $site, $request );

        my $results = $class->fulltext_ebsco( $text, $record, $resource, $site, $request );

        push @results, @$results;
    }

    return \@results;
}

sub build_linkJournal {
    my ( $class, $records, $resource, $site, $request ) = @_;

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

        my $db         = $resource->resource_identifier;
        my $journal_id = $record->db_identifier;
        next if is_empty_string($db) || is_empty_string($journal_id);

        $db = lc($db);

        my $result = new CUFTS::Result("http://search.ebscohost.com/direct.asp?db=${db}&jid=${journal_id}&scope=site");
        $result->record($record);

        push @results, $result;
    }

    return \@results;
}

sub build_linkDatabase {
    my ( $class, $records, $resource, $site, $request ) = @_;

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

sub check_article_matcher {
    my ( $class, $XML ) = @_;

    my $cache = CUFTS::DB::SearchCache->search( 'type' => 'ebsco', 'query' => $XML )->first;
    if ( defined($cache) ) {
        return $cache->result;
    }

    my $URL = 'http://articlematcher.epnet.com/EpAmRc.dll';

    my $ua = new LWP::UserAgent;
    $ua->agent('CUFTS-Fulltext/0.1');

    my $request = HTTP::Request->new( POST => $URL );
    $request->content($XML);
    my $response = $ua->simple_request($request);

    CUFTS::DB::SearchCache->create(
        {   type   => 'ebsco',
            query  => $XML,
            result => $response->content,
        }
    );
    CUFTS::DB::SearchCache->dbi_commit;

    return $response->content;
}

##
## Produce XML for passing to Ebsco's Article Matcher which is
## dumped into the POST request.
##

sub produce_ebsco_xml {
    my ( $class, $record, $resource, $site, $request ) = @_;

    if ( is_empty_string( $resource->resource_identifier ) ) {
        warn('No resource_identifier defined for EBSCO linking: ' . $resource->name);
        return undef;
#        CUFTS::Exception::App->throw('No resource_identifier defined for EBSCO linking.');
    }

    if ( is_empty_string( $resource->auth_name ) ) {
        warn('No auth_name defined for EBSCO linking for site: ' . $site->key);
        return undef;
#        CUFTS::Exception::App->throw('No auth_name defined for EBSCO linking.');
    }

    my $xml_string = "XML=<?xml version=\"1.0\"?>\n";

    $xml_string .= <<EOT
<request>
 <hosts>
  <minimum-match-percent>1</minimum-match-percent>
  <xdebug-mode>1</xdebug-mode>
  <validation-level>precise</validation-level>
  <host id="1">
   <host-name>EHOST</host-name>
EOT
;

    $xml_string .= '   <user-id>' . $resource->auth_name . "</user-id>\n";
    $xml_string .= "   <authenticated-databases>\n";
    my $db = $resource->resource_identifier;
    $db =~ s/&.+$//;  # remove possible trailing "&site=bsi"
    $xml_string .= "    <db>$db</db>\n";

    $xml_string .= <<EOT
   </authenticated-databases>
   <display-scope>object</display-scope>
  </host>
 </hosts>
 <citations>
  <cite id="1">
EOT
;

    $xml_string .= "   <jinfo>\n";

    my $journal_title = $record->title;
    $journal_title =~ s/&/ and /g;
    $journal_title =~ s/[<>]//g;

    $xml_string .= "    <jtl>" . $journal_title . "</jtl>\n"
        if defined( $record->title );
    $xml_string .= "    <issn>" . $record->issn . "</issn>\n"
        if defined( $record->issn );
    $xml_string .= "   </jinfo>\n";

    # Publishing info

    if (   defined( $request->issue )
        || defined( $request->volume )
        || defined( $request->date ) )
    {
        $xml_string .= "   <pubinfo>\n";
        $xml_string .= "    <vid>" . $request->volume . "</vid>\n"
            if defined( $request->volume );
        $xml_string .= "    <iid>" . $request->issue . "</iid>\n"
            if defined( $request->issue );
        if ( defined( $request->year ) ) {
            $xml_string .= "    <cd year=\"" . $request->year . "\"";

            # PUT DAY/MONTH STUFF HERE
            $xml_string .= "/>\n";
        }

        $xml_string .= "   </pubinfo>\n";
    }

    if ( defined( $request->spage ) || defined( $request->atitle ) ) {
        $xml_string .= "   <genhdr>\n";
        $xml_string .= "    <artinfo>\n  <ppf>"
            . $request->spage
            . "</ppf>\n   </artinfo>\n"
            if defined( $request->spage );

        if ( defined( $request->atitle ) ) {
            my $atitle = $request->atitle;
            $atitle =~ s/&/ and /g;
            $atitle =~ s/[<>]//g;

            $xml_string
                .= "    <tig>\n    <atl>" . $atitle . "</atl>\n   </tig>\n";
        }

        $xml_string .= "   </genhdr>\n";
    }

    $xml_string .= <<EOT
  </cite>
 </citations>
</request>
EOT
;

    #	warn("\n\nDEBUG XML: $xml_string\n\n");

    return $xml_string;
}

sub preparse_ebsco_fulltext($) {
    my ( $class, $text, $record, $resource, $site, $request ) = @_;

#	warn("\n\nDEBUG EBSCO RESULTS: $text\n\n");

    my @match_list = ( $text =~ m#(<object-information>.+?</object-information>)#sgi );
    my @sorted;
    if ( scalar(@match_list) > 1 ) {
        @sorted = reverse sort {
            my ( $a1, $b1 );
            if ( $a =~ m#<match-percent>(\d+)</match-percent>#is ) {
                $a1 = $1;
            }
            else {
                CUFTS::Exception::App->throw("Bad data passed to sort in preparse_ebsco_fulltext");
            }
            if ( $b =~ m#<match-percent>(\d+)</match-percent>#is ) {
                $b1 = $1;
            }
            else {
                CUFTS::Exception::App->throw("Bad data passed to sort in preparse_ebsco_fulltext");
            }
            $a1 cmp $b1;
        } @match_list;
    }
    else {
        @sorted = @match_list;
    }

    if ( scalar(@match_list) < 1 ) {
        return $text;
    }
    return join " ", @sorted;
}

sub fulltext_ebsco {
    my ( $class, $text, $record, $resource, $site, $request ) = @_;

    my @results;
    while ( $text =~ m#<object-information>(.+?)</object-information>#sgi ) {
        my $object = $1;
        next unless $object =~ m#<URL>(.+?)</URL>#s;

        my $url = HTML::Entities::decode($1);

        my $result = new CUFTS::Result($url);
        $result->record($record);

        if ( $object =~ m#<atl>(.+?)</atl># ) {
            $result->atitle( HTML::Entities::decode($1) );
        }
        push @results, $result;
    }

    return \@results;
}

1;
