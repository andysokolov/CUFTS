## CUFTS::DB::ERMKeywords
##
## Copyright Todd Holbrook, Simon Fraser University (2003)
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

package CUFTS::Schema::ERMKeywords;

use strict;
use base qw/DBIx::Class/;

use CUFTS::Util::Simple;

__PACKAGE__->load_components(qw/PK::Auto Core/);

__PACKAGE__->table('erm_keywords');
__PACKAGE__->add_columns( qw(
    id
    erm_main
    keyword
));                                                                                                        

__PACKAGE__->set_primary_key( 'id' );

__PACKAGE__->belongs_to('erm_main', 'CUFTS::Schema::ERMMain');

sub store_column {
    my ( $self, $name, $value ) = @_;

    if ($name eq 'keyword') {
        $value = $self->strip_keyword($value);
    }

    $self->next::method($name, $value);
}
  
  
sub strip_keyword {
    my ( $class, $name ) = @_;
    
    # $name =~ s/\s+\&\s+/ and /g;
    $name = lc($name);
    # $name = CUFTS::Util::Simple::convert_diacritics( $name );
    # $name =~ s/[^a-z0-9 ]//g;
    $name =~ s/\s\s+/ /g;
    $name = trim_string($name);
    
    return $name;
}

1;
