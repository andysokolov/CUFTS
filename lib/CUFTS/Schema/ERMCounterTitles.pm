## CUFTS::Schema::ERMCounterTitles
##
## Copyright Todd Holbrook, Simon Fraser University (2007)
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

package CUFTS::Schema::ERMCounterTitles;

use strict;
use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/Core/);

__PACKAGE__->table('erm_counter_titles');
__PACKAGE__->add_columns(
    id => {
      data_type => 'integer',
      is_auto_increment => 1,
      is_nullable => 0,
      size => 8,
    },
    title => {
        data_type => 'varchar',
        size => 1024,
        is_nullable => 0,
    },
    issn => {
        data_type => 'varchar',
        size => 8,
        is_nullable => 1,
    },
    e_issn => {
        data_type => 'varchar',
        size => 8,
        is_nullable => 1,
    },
    journal_auth => {
        data_type => 'integer',
        size => 8,
    },
);                                                                                               

__PACKAGE__->set_primary_key( 'id' );

# __PACKAGE__->might_have( 'journal_auth' => 'CUFTS::Schema::JournalsAuth' );

sub store_column {
    my ( $self, $name, $value ) = @_;

    if ( ($name eq 'issn' || $name eq 'e_issn') && defined($value) ) {
        $value = uc($value);
        $value =~ s/(\d{4})\-?(\d{3}[\dxX])/$1$2/ or
            $value = undef;
    }
    
    if ( $name eq 'title' ) {
        $value =~ s/^\s+//;
        $value =~ s/[\n\s]+$//;
    }

    $self->next::method($name, $value);
}


1;
