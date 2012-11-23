package CUFTS::Resources::eLibrary;

use base qw(CUFTS::Resources::Base::Journals);

use CUFTS::Exceptions;
use CUFTS::Util::Simple;

use strict;

## title_list_fields - Controls what fields get displayed and loaded from
## title lists.

sub title_list_fields {
    return [
        qw(
            id
            title
            issn
            ft_start_date
            ft_end_date
            journal_url
            publisher
        )
    ];
}

sub title_list_field_map {
    return {
        'Title'  		=> 'title',
        'ISSN'             	=> 'issn',
        'URL'     		=> 'journal_url',
        'Publisher'        	=> 'publisher',
        'Period'   		=> '___Period',
    };
}

sub clean_data {
    my ( $class, $record ) = @_;

    my $fulltext = $record->{'___Period'};

    if ( not_empty_string( $fulltext ) ) {

        if ( $fulltext =~ m{^ \s* (\d{1,2}) . (\d{4})}xsm ) {
            $record->{ft_start_date} = "$2-$1";
        }

        if ( $fulltext =~ m{ - \s+ (\d{1,2}) . (\d{4})}xsm ) {
            $record->{ft_end_date} = "$2-$1";
        }
    }
    
    
    return $class->SUPER::clean_data($record);
}

## build_link* - Builds a link to a service.  Should return an array reference containing
## Result objects with urls and title list records (if applicable).
##

sub build_linkJournal {
    my ( $class, $records, $resource, $site, $request ) = @_;

    defined($records) && scalar(@$records) > 0
        or return [];
    defined($resource)
        or CUFTS::Exception::App->throw('No resource defined in build_linkJournal');
    defined($site)
        or
        CUFTS::Exception::App->throw('No site defined in build_linkJournal');
    defined($request)
        or CUFTS::Exception::App->throw('No request defined in build_linkJournal');

    my @results;

    foreach my $record (@$records) {

        my $result = new CUFTS::Result($record->journal_url);
        $result->record($record);

        push @results, $result;
    }

    return \@results;
}

sub build_linkDatabase {
    my ( $class, $records, $resource, $site, $request ) = @_;

    defined($records) && scalar(@$records) > 0
        or return [];
    defined($resource)
        or CUFTS::Exception::App->throw('No resource defined in build_linkDatabase');
    defined($site)
        or CUFTS::Exception::App->throw('No site defined in build_linkDatabase');
    defined($request)
        or CUFTS::Exception::App->throw('No request defined in build_linkDatabase');

    my @results;

    foreach my $record (@$records) {

        my $url = $resource->database_url 
                  || 'http://elibrary.ru/';

        my $result = new CUFTS::Result($url);
        $result->record($record);

        push @results, $result;
    }

    return \@results;
}

1;
