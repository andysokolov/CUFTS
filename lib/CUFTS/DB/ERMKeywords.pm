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

package CUFTS::DB::ERMKeywords;

use strict;
use base 'CUFTS::DB::DBI';
use CUFTS::Util::Simple;

__PACKAGE__->table('erm_keywords');
__PACKAGE__->columns(Primary => 'id');
__PACKAGE__->columns(All => qw(
    id
    erm_main
    keyword
));                                                                                                        
__PACKAGE__->columns(Essential => __PACKAGE__->columns);
__PACKAGE__->sequence('erm_keywords_id_seq');

__PACKAGE__->has_a('erm_main', 'CUFTS::DB::ERMMain');

sub normalize_column_values {
    my ( $self, $values ) = @_;

    $values->{keyword} = $self->strip_keyword( $values->{keyword} );

    return 1;
}


sub strip_keyword {
    my ( $class, $keyword ) = @_;
    
    $keyword =~ s/\s+\&\s+/ and /g;
    $keyword = lc($keyword);
    # $keyword = CUFTS::Util::Simple::convert_diacritics( $keyword );
    # $keyword =~ s/[^a-z0-9 ]//g;
    $keyword =~ s/\s\s+/ /g;
    $keyword = trim_string($keyword);
    
    return $keyword;
}

1;
