## CUFTS::Resources::MetaPress
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

package CUFTS::Resources::MetaPress;

use base qw(CUFTS::Resources::Base::DOI CUFTS::Resources::Base::Journals);

use CUFTS::Exceptions;
use CUFTS::Util::Simple;

use Unicode::String qw(utf8);

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
            e_issn

            ft_start_date
            ft_end_date
            vol_ft_start
            iss_ft_start
            vol_ft_end
            iss_ft_end

            publisher
        )
    ];
}

## title_list_field_map - Hash ref mapping fields from the raw title lists to
## internal field names
##

sub title_list_field_map {
    return {
        'Journal'                => 'title',
        'Name'                   => 'title',
        'Print ISSN'             => 'issn',
        'Print Issn'             => 'issn',
        'Print Issn/Isbn'        => 'issn',
        'Online ISSN'            => 'e_issn',
        'Online Issn'            => 'e_issn',
        'Online Issn/Isbn'       => 'e_issn',
        'Oldest Cover Date'      => 'ft_start_date',
        'Oldest CoverDate'       => 'ft_start_date',
        'Most Recent Cover Date' => 'ft_end_date',
        'Newest CoverDate'       => 'ft_end_date',
        'Oldest Volume'          => 'vol_ft_start',
        'Oldest Issue'           => 'iss_ft_start',
        'Most Recent Issue'      => 'iss_ft_end',
        'Newest Issue'           => 'iss_ft_end',
        'Most Recent Volume'     => 'vol_ft_end',
        'Newest Volume'          => 'vol_ft_end',
        'Publisher'              => 'publisher',
    };
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

sub clean_data {
    my ( $class, $record ) = @_;
    my @errors;

    $class->SUPER::clean_data($record);

    if (defined( $record->{'___Notes'} )
        && (   $record->{'___Notes'} =~ /^Database/
            || $record->{'___Notes'} =~ /^No\sissues/ )
        )
    {
        return ['Skipping due to no holdings at Metapress'];
    }

    if ( defined( $record->{ft_start_date} ) ) {
        $record->{ft_start_date} = parse_date( $record->{ft_start_date} );
    }
    if ( defined( $record->{ft_end_date} ) ) {
        $record->{ft_end_date} = parse_date( $record->{ft_end_date} );

        # Drop end dates if they're this or last year

        if ( $record->{ft_end_date} =~ /^(\d{4})/ ) {
            my $year = (localtime())[5] + 1900 - 1;
            if ( $1 >= $year ) {
                delete $record->{ft_end_date};
                delete $record->{vol_ft_end};
                delete $record->{iss_ft_end};
            }
        }
    }

    foreach my $field ( qw( vol_ft_start vol_ft_end iss_ft_start iss_ft_end ) ) {
        if ( defined($record->{$field}) ) {
            if ( $record->{$field} eq '-1' ) {
                delete $record->{$field};
            }
            else {
                $record->{$field} =~ tr/0-9//cd;
            }
        }
    }


    if ( defined( $record->{title} ) ) {
        $record->{title} =~ s/\([^\)]+?\)$//;
        $record->{title} = utf8( $record->{title} )->latin1;
    }

    if ( defined( $record->{'publisher'} ) ) {
        $record->{publisher} = trim_string( $record->{publisher}, '"' );
        $record->{publisher} = utf8($record->{'publisher'})->latin1;
    }

    sub parse_date {
        my ($date) = @_;

        my ( $month, $day, $year );

        if ( ( $year, $month, $day ) = $date =~ m{ (\d{4}) - (\d{1,2}) - (\d{1,2}) }xsm ) {
            return sprintf( "%04i-%02i-%02i", $year, $month, $day );
        }
        elsif ( ( $day, $month, $year ) = $date =~ m{ (\d{1,2}) / (\d{1,2}) / (\d{4}) }xsm ) {
            return sprintf( "%04i-%02i-%02i", $year, $month, $day );
        }
        elsif ( ( $day, $month, $year ) = $date =~ m{ (\d{1,2}) / (\d{1,2}) / (\d{2}) }xsm ) {
            $year += $year < 20 ? 2000 : 1900;
            return sprintf( "%04i-%02i-%02i", $year, $month, $day );
        }
        elsif ( ( $month, $day, $year ) = $date =~ / (\w+) \s+ (\d+) \s+ (\d{4}) /xsm ) {
            if    ( $month =~ /^Jan/i ) { $month = 1 }
            elsif ( $month =~ /^Feb/i ) { $month = 2 }
            elsif ( $month =~ /^Mar/i ) { $month = 3 }
            elsif ( $month =~ /^Apr/i ) { $month = 4 }
            elsif ( $month =~ /^May/i ) { $month = 5 }
            elsif ( $month =~ /^Jun/i ) { $month = 6 }
            elsif ( $month =~ /^Jul/i ) { $month = 7 }
            elsif ( $month =~ /^Aug/i ) { $month = 8 }
            elsif ( $month =~ /^Sep/i ) { $month = 9 }
            elsif ( $month =~ /^Oct/i ) { $month = 10 }
            elsif ( $month =~ /^Nov/i ) { $month = 11 }
            elsif ( $month =~ /^Dec/i ) { $month = 12 }
            return sprintf( "%04i-%02i-%02i", $year, $month, $day );
        }

        return undef;
    }
}

## --------------------------------------------------------------------------------------------

## build_link* - Builds a link to a service.  Should return an array reference containing
## Result objects with urls and title list records (if applicable).
##

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

    if ( is_empty_string( $resource->url_base ) ) {
        CUFTS::Exception::App->throw('No url_base set for resource');
    }

    my @results;

    foreach my $record (@$records) {

        next if is_empty_string( $record->issn   )
             && is_empty_string( $record->e_issn );

        my $url = $resource->url_base;
        $url .= '?genre=journal';
        if ( not_empty_string( $record->e_issn ) ) {
            $url .= '&issn=' . dashed_issn($record->e_issn);
        }
        else {
            $url .= '&issn=' . dashed_issn($record->issn);
        }

        my $result = new CUFTS::Result($url);
        $result->record($record);

        push @results, $result;
    }

    return \@results;
}

sub can_getTOC {
    my ( $class, $request ) = @_;

    return 0 if is_empty_string( $request->issue  )
             && is_empty_string( $request->volume );

    return $class->SUPER::can_getTOC($request);
}

sub can_getFulltext {
    my ( $class, $request ) = @_;

    return 0 if is_empty_string( $request->issue )
             || is_empty_string( $request->spage );

    return $class->SUPER::can_getTOC($request);
}

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

    if ( is_empty_string( $resource->url_base ) ) {
        CUFTS::Exception::App->throw('No url_base set for resource');
    }

    my @results;

    foreach my $record (@$records) {

        next if is_empty_string( $record->issn   )
             && is_empty_string( $record->e_issn );

        my $url = $resource->url_base;
        $url .= '?genre=journal';
        if ( not_empty_string( $record->e_issn ) ) {
            $url .= '&issn=' . dashed_issn($record->e_issn);
        }
        else {
            $url .= '&issn=' . dashed_issn($record->issn);
        }

        if ( not_empty_string( $request->issue ) ) {
            $url .= '&issue=' . $request->issue;
        }
        if ( not_empty_string( $request->volume ) ) {
            $url .= '&volume=' . $request->volume;
        }

        my $result = new CUFTS::Result($url);
        $result->record($record);

        push @results, $result;
    }

    return \@results;
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

    if ( is_empty_string( $resource->url_base ) ) {
        CUFTS::Exception::App->throw('No url_base set for resource');
    }

    my @results;
    foreach my $record (@$records) {

        next if is_empty_string( $record->issn   )
             && is_empty_string( $record->e_issn );

        my $url = $resource->url_base;
        $url .= '?genre=article';
        if ( not_empty_string( $record->e_issn ) ) {
            $url .= '&issn=' . dashed_issn($record->e_issn);
        }
        else {
            $url .= '&issn=' . dashed_issn($record->issn);
        }

        if ( not_empty_string( $request->volume ) ) {
            $url .= '&volume=' . $request->volume;
        }

        if ( not_empty_string( $request->issue ) ) {
            my $issue = $request->issue;
            $issue =~ s/^([0-9]+).*$/$1/;
            $url .= '&issue=' . $issue;
        }

        $url .= '&spage=' . $request->spage;

        my $result = new CUFTS::Result($url);
        $result->record($record);

        push @results, $result;
    }

    return \@results;
}

1;

__DATA__
ContentType	Name	DOI	OpenURL	Direct Link	Publisher	Print Issn/Isbn	Online Issn/Isbn	Subject	Oldest Volume	Oldest Issue	Oldest CoverDate	Newest Volume	Newest Issue	Newest CoverDate	Oldest Volume with Abstracts	Oldest Issue with Abstracts	Oldest CoverDate with Abstracts	Newest Volume with Abstracts	Newest Issue with Abstracts	Newest CoverDate with Abstracts	Copyright	Series / Parent Publication	Author / Editor	Subtitle	Volume	Issue	Pages	Notes
Journal	4OR: A Quarterly Journal of Operations Research		http://www.metapress.com/openurl.asp?genre=journal&issn=1619-4500	http://www.metapress.com/content/111812	Springer Berlin / Heidelberg	1619-4500	1614-2411		Volume 1	1	01/03/2003	Volume 6	3	01/09/2008	Volume 1	1	01/03/2003	Volume 6	3	01/09/2008
Journal	The AAPS Journal		http://www.metapress.com/openurl.asp?genre=journal&eissn=1550-7416	http://www.metapress.com/content/120921	Springer New York		1550-7416		Volume 1	2	10/06/1999	Volume 10	1	22/03/2008	Volume 1	2	10/06/1999	Volume 10	1	22/03/2008
Journal	AAPS PharmSciTech		http://www.metapress.com/openurl.asp?genre=journal&eissn=1530-9932	http://www.metapress.com/content/120971	Springer New York		1530-9932		Volume 1	1	12/03/2000	Volume 9	2	01/06/2008	Volume 1	1	12/03/2000	Volume 9	2	01/06/2008
Journal	Abdominal Imaging		http://www.metapress.com/openurl.asp?genre=journal&issn=0942-8925	http://www.metapress.com/content/100116	Springer New York	0942-8925	1432-0509		Volume 1	1	25/12/1976	Volume 33	5	01/09/2008	Volume 1	1	25/12/1976	Volume 33	5	01/09/2008
Journal	Abhandlungen aus dem Mathematischen Seminar der Universität Hamburg		http://www.metapress.com/openurl.asp?genre=journal&issn=0025-5858	http://www.metapress.com/content/120934	Springer Berlin / Heidelberg	0025-5858	1865-8784		Volume 6	1	01/12/1928	Volume 75	1	01/12/2005	Volume 6	1	01/12/1928	Volume 75	1	01/12/2005
Journal	Abstracts of the Papers Communicated to the Royal Society of London (1843-1854)		http://www.metapress.com/openurl.asp?genre=journal&issn=0365-0855	http://www.metapress.com/content/120145	The Royal Society	0365-0855			Volume 5	-1	1843-01-01	Volume 6	-1	1850-01-01
Journal	Artificial Intelligence Review		http://www.metapress.com/openurl.asp?genre=journal&issn=0269-2821	http://www.metapress.com/content/100240	Springer Netherlands	0269-2821	1573-7462		Volume 1	1	01/03/1986	Volume 26	4	09/12/2006	Volume 1	1	01/03/1986	Volume 24	3	09/11/2005
Journal	Artificial Life and Robotics		http://www.metapress.com/openurl.asp?genre=journal&issn=1433-5298	http://www.metapress.com/content/112249	Springer Japan	1433-5298	1614-7456		Volume 1	1	10/03/1997	Volume 12	1	01/03/2008	Volume 1	1	10/03/1997	Volume 12	1	01/03/2008
Journal	Artificial Satellites		http://www.metapress.com/openurl.asp?genre=journal&issn=0208-841X	http://www.metapress.com/content/120727	Versita	0208-841X			Volume 41	1	01/01/2006	Volume 42	3	01/01/2007	Volume 41	1	01/01/2006	Volume 42	2	01/01/2007
Journal	Arts Education Policy Review		http://www.metapress.com/openurl.asp?genre=journal&issn=1063-2913	http://www.metapress.com/content/119955	"Heldref Publications, a division of the Helen Dwight Reid Educational Foundation"	1063-2913	1940-4395		Volume 105	3	01/01/2004	Volume 109	5	01/05/2008	Volume 108	3	01/01/2007	Volume 109	5	01/05/2008
Journal	Asia Europe Journal		http://www.metapress.com/openurl.asp?genre=journal&issn=1610-2932	http://www.metapress.com/content/110364	Springer Berlin / Heidelberg	1610-2932	1612-1031		Volume 1	1	24/02/2003	Volume 6	2	01/06/2008	Volume 1	1	24/02/2003	Volume 5	4	22/01/2008
