## CUFTS::Resources::PubMed
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

package CUFTS::Resources::PubMed;

##
## Use PubMed lookups to fill in metadata if a PMID is present
##

use base qw(CUFTS::Resources);

use CUFTS::Exceptions;
use CUFTS::Util::Simple;
use CUFTS::DB::SearchCache;

use LWP::UserAgent;
use HTTP::Request::Common;
use XML::DOM;
use Data::Dumper;

use strict;

sub services {
    return [ qw( metadata ) ];
}

my $month_lookup = {
    'jan' => '01',
    'feb' => '02',
    'mar' => '03',
    'apr' => '04',
    'may' => '05',
    'jun' => '06',
    'jul' => '07',
    'aug' => '08',
    'sep' => '09',
    'oct' => '10',
    'nov' => '11',
    'dec' => '12',
};

sub has_title_list { return 0; }
sub help_template { return undef }

sub get_records {
	my ($class, $schema, $resource, $site, $request) = @_;

    my $pmid = $request->pmid;
    return undef if is_empty_string($pmid);

	my $data;

    # Check the cache

    my $cache_data = $schema->resultset('SearchCache')->search({ type => 'pubmed', query => $pmid })->first;

    if ( defined $cache_data ) {
        no strict;  # Dumper's $VAR1 will cause errors without this
        $data = eval($cache_data->result);
	}
	else {
    	# Lookup meta-data

    	my $start_time = time;

    	my $ua = LWP::UserAgent->new('timeout' => 10);
    	my $response = $ua->request(POST 'http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi', [
    		db   => 'pubmed',
    		id   => $pmid,
    		mode => 'xml',
    		tool => 'CUFTS',
    	]);

    	return undef if !$response->is_success;

    	my $returned_data = trim_string($response->content);

    	print STDERR "PubMed lookup returned in " . (time-$start_time) . " seconds\n";
#        print STDERR $returned_data;

    	$data = parse_pubmed_data($returned_data);

    	$cache_data = $schema->resultset('SearchCache')->create({
    	    type   => 'pubmed',
    	    query  => $pmid,
    	    result => Data::Dumper->Dump([$data]),
    	});
    }

    foreach my $field ( qw( title atitle issn eissn volume issue pages spage epage date ) ) {
    	if ( is_empty_string($request->$field) && not_empty_string($data->{$field}) ) {
    		$request->$field($data->{$field});
    	}
    }


	return undef;
}

sub can_getMetadata {
	my ($class, $request) = @_;

	not_empty_string($request->pmid) and
		return 1;

	return 0;
}

sub parse_pubmed_data {
    my $input = shift;

    my $data = {};

    my $parser = XML::DOM::Parser->new;
    my $doc = $parser->parse($input);

    my $articles = $doc->getElementsByTagName('PubmedArticle');
    if ( $articles->getLength == 0 ) {
        # No results
    } else {
        if ( $articles->getLength > 1 ) {
            warn("Multiple articles returned for PMID.  Processing first one only.");
        }
        my $article = $articles->item(0);

        $data->{atitle } = trim_string( ($article->getElementsByTagName( 'ArticleTitle' )->item(0)->getChildNodes)[0]->getNodeValue() );
        $data->{title  } = trim_string( ($article->getElementsByTagName( 'Title'        )->item(0)->getChildNodes)[0]->getNodeValue() );
        $data->{volume } = trim_string( ($article->getElementsByTagName( 'Volume'       )->item(0)->getChildNodes)[0]->getNodeValue() );
        $data->{issue  } = trim_string( ($article->getElementsByTagName( 'Issue'        )->item(0)->getChildNodes)[0]->getNodeValue() );

        my $pubdate = $article->getElementsByTagName('PubDate')->item(0);
        eval {
            $data->{date_year } = trim_string( ($pubdate->getElementsByTagName('Year' )->item(0)->getChildNodes)[0]->getNodeValue() );
            $data->{date_month} = trim_string( ($pubdate->getElementsByTagName('Month')->item(0)->getChildNodes)[0]->getNodeValue() );
            $data->{date_day  } = trim_string( ($pubdate->getElementsByTagName('Day'  )->item(0)->getChildNodes)[0]->getNodeValue() );
        };

        if ( $data->{date_month} !~ /^\d+$/ ) {
            $data->{date_month} = $month_lookup->{ lc($data->{date_month}) };
        }

        if ( $data->{date_year} =~ /^\d{4}$/ ) {
            $data->{date} = $data->{date_year};
            if ( $data->{date_month} =~ /^\d\d?$/ ) {
                $data->{date} .= '-' . $data->{date_month};
                if ( $data->{date_day} =~ /^\d\d?$/ ) {
                    $data->{date} .= '-' . $data->{date_day};
                }
            }
        }

        eval {
            $data->{spage} = trim_string( ($article->getElementsByTagName('StartPage')->item(0)->getChildNodes)[0]->getNodeValue() );
        };
        eval {
            $data->{epage} = trim_string( ($article->getElementsByTagName('EndPage')->item(0)->getChildNodes)[0]->getNodeValue() );
        };
        if ( !defined($data->{spage}) ) {
            eval {
                $data->{pages} = trim_string( ($article->getElementsByTagName('MedlinePgn')->item(0)->getChildNodes)[0]->getNodeValue() );
            };

            if ( defined($data->{pages}) && $data->{pages} =~ /^ (\d+) - (\d+) $/xsm ) {
                $data->{spage} = $1;
                $data->{epage} = $2;

                # Change page ranges 1123-33 into 1123 and 1133

                my $length = length($data->{spage}) - length($data->{epage});
                if ($length > 0) {
                    $data->{epage} = substr($data->{spage}, 0, $length) . $data->{epage};
                }
            }
        }

        my $issn_nodes = $article->getElementsByTagName('ISSN');
        my $n          = $issn_nodes->getLength;

        foreach my $i ( 0 .. $n - 1 ) {
            my $issn = $issn_nodes->item($i);
            my $attr = $issn->getAttribute('IssnType');
            my $issn_string = trim_string( ($issn->getChildNodes)[0]->getNodeValue() );
            if ($issn_string =~ /^ (\d{4}) -? (\d{3}[\dxX]) $/xsm ) {
                $issn_string = "$1$2";

                if ( $attr eq 'Electronic' ) {
                    $data->{eissn} ||= $issn_string;
                } else {
                    $data->{issn} ||= $issn_string;
                }
            }
        }

    }

    return $data;

}

1;
