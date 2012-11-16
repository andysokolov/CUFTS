## CUFTS::DB::ERMUses
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

package CUFTS::DB::ERMUses;

use strict;
use base 'CUFTS::DB::DBI';


__PACKAGE__->table('erm_uses');
__PACKAGE__->columns(Primary => 'id');
__PACKAGE__->columns(All => qw(
    id
    erm_main
    date
));                                        
__PACKAGE__->columns(Essential => __PACKAGE__->columns);

__PACKAGE__->sequence('erm_uses_id_seq');

__PACKAGE__->has_a('erm_main', 'CUFTS::DB::ERMMain');


__PACKAGE__->set_sql('count_grouped_with_name' => qq{
    SELECT erm_uses.erm_main AS erm_main, erm_names.name AS name, COUNT(*), %s AS date_trunc FROM
    erm_uses
    JOIN erm_names ON ( erm_uses.erm_main = erm_names.id )
    WHERE date BETWEEN ? AND ?
    AND erm_uses.erm_main IN (%s)
    AND erm_names.main = 1
    GROUP BY date_trunc, erm_uses.erm_main, name
    ORDER BY date_trunc, name
});

__PACKAGE__->set_sql('count_grouped' => qq{
    SELECT erm_uses.erm_main AS erm_main, COUNT(*), %s AS date_trunc FROM
    erm_uses
    WHERE date BETWEEN ? AND ?
    AND erm_uses.erm_main IN (%s)
    GROUP BY date_trunc, erm_uses.erm_main
    ORDER BY date_trunc
});

sub count_grouped {
    my ( $class, $granularity, $start_date, $end_date, $erm_mains ) = @_;

    # Granularity isn't in a bind variable so make sure it's clean.
    $granularity = (grep { $_ eq $granularity } qw( year month day ))[0]
        or die("Unrecognized granularity: $granularity");

    my $date_trunc = "DATE_TRUNC('$granularity', date)";
    my $erm_mains_string = join(',', map { int($_) } @$erm_mains );  # Also not a bind variable, clean with "int()"
    
    my $sth = $class->sql_count_grouped($date_trunc, $erm_mains_string);
    $sth->execute($start_date, $end_date);
    my $records = $sth->fetchall_arrayref;

    return $records;
}


1;
