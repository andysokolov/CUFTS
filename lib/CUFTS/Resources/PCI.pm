## CUFTS::Resources::PCI
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

# This resource is for some Chadwick/Healey databases on www.proquest.co.uk
# Simple parsing of the title list should be done, however we need access to
# the database through someone who subscribes to see whether linking will
# be possible.


package CUFTS::Resources::PCI;

use base qw(CUFTS::Resources::Base::Journals);

use CUFTS::Exceptions qw(assert_ne);

use strict;

sub title_list_fields {
    return [qw(
        id

        title
        issn

        ft_start_date
        ft_end_date
    )];
}

sub overridable_resource_details {
    return undef;
}


sub title_list_field_map {
    return {
        'Maintitle'         => 'title',
        'ISSN'          => 'issn',

    };
}

sub clean_data {
    my ($self, $record) = @_;

    # Strip quotes from titles

    $record->{'title'} =~ s/^"/;
    $record->{'title'} =~ s/"$/;

    # Figure out fulltext field

    my $ft_field;
    foreach my $field (keys $record) {
        if ($field =~ /^___.+Full\s+Text\s+coverage/i) {
            $ft_field = $field;
            last;
        }
    }

    if (defined($ft_field)) {
        my $coverage = $record->{$ft_field};
        if ($coverage =~ /(\d{4}).*\-.*(\d{4})/) {
            $record->{'ft_start_date'} = $1;
            $record->{'ft_end_date'} = $2;
        } elsif ($coverage =~ /(\d{4})/) {
            $record->{'ft_start_date'} = $1;
        }
    }

    return $self->SUPER::clean_data($record);
}



sub can_getFulltext {
    return 0;
}
sub can_getTOC {
    return 0;
}

1;
