## CUFTS::Resources::CH_PCI
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

package CUFTS::Resources::CH_PCI;

use base qw(CUFTS::Resources::Base::Journals);

use URI::Escape qw(uri_escape);
use CUFTS::Exceptions;
use CUFTS::Util::Simple;

use strict;

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

sub title_list_field_map {
    return {
        'Maintitle' => 'title',
        'ISSN'      => 'issn',
    };
}

sub skip_record {
    my ( $class, $record ) = @_;

    defined( $record->{'ft_start_date'} )
        or return 1;

    return 0;
}

sub clean_data {
    my ( $self, $record ) = @_;

    $record->{title} =~ s{^ \s* " \s* }{}xsm;
    $record->{title} =~ s{ \s* " \s* $}{}xsm;

    $record->{title} =~ s{ \s* \( .+ \) \s* $}{}xsm;

    $record->{'___Current PCI Full Text coverage'} =~ s/^"(.+)"$/$1/;

    if ( defined( $record->{'___Current PCI Full Text coverage'} )
        && $record->{'___Current PCI Full Text coverage'} =~ /^\s*(\d{4}).+(\d{4})[^\d]*$/ )
    {
        $record->{ft_start_date} = $1;
        $record->{ft_end_date}   = $2;
    }

    return $self->SUPER::clean_data($record);
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
        my $url = 'http://gateway.proquest.com/openurl?ctx_ver=Z39.88-2003&ctx_fmt=ori:format:pl:ebnf:context'
                . '&rft_val_fmt=ori:format:pl:ebnf:journal&res_id=xri:pcift-us&res_dat=xri:pqil:res_ver=0.1';

        if ( not_empty_string( $record->issn ) ) {
            $url .= '&issn=' . $record->issn;
        }
        else {
            $url .= '&title=' . uri_escape( $record->title );
        }

        my $result = new CUFTS::Result($url);
        $result->record($record);

        push @results, $result;
    }

    return \@results;
}

sub build_linkDatabase {
    my ( $class, $schema, $records, $resource, $site, $request ) = @_;

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

        my $url = $resource->database_url || 'http://pcift.chadwyck.com/pcift/search';

        my $result = new CUFTS::Result($url);
        $result->record($record);

        push @results, $result;
    }

    return \@results;
}

1;
