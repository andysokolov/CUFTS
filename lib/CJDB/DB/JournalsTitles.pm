## CJDB::DB::JournalsTitles
##
## Copyright Todd Holbrook, Simon Fraser University (2003)
##
## This file is part of CJDB.
##
## CJDB is free software; you can redistribute it and/or modify it under
## the terms of the GNU General Public License as published by the Free
## Software Foundation; either version 2 of the License, or (at your option)
## any later version.
##
## CJDB is distributed in the hope that it will be useful, but WITHOUT ANY
## WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
## FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
## details.
##
## You should have received a copy of the GNU General Public License along
## with CJDB; if not, write to the Free Software Foundation, Inc., 59
## Temple Place, Suite 330, Boston, MA 02111-1307 USA

package CJDB::DB::JournalsTitles;

use strict;
use base 'CJDB::DB::DBI';
use CJDB::DB::Journals;
use CJDB::DB::Titles;

__PACKAGE__->table('cjdb_journals_titles');
__PACKAGE__->columns( Primary => 'id' );
__PACKAGE__->columns(
    All => qw(
        id
        journal
        title
        site
        main
));

__PACKAGE__->columns( Essential => __PACKAGE__->columns );
__PACKAGE__->sequence('cjdb_journals_titles_id_seq');

__PACKAGE__->has_a( 'journal' => 'CJDB::DB::Journals' );
__PACKAGE__->has_a( 'title'   => 'CJDB::DB::Titles' );

1;
