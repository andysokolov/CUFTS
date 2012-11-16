## CJDB::DB::Tags
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

package CJDB::DB::Tags;

use strict;
use base 'CJDB::DB::DBI';

use CUFTS::DB::JournalsAuth;
use CUFTS::DB::Sites;
use CJDB::DB::Accounts;

__PACKAGE__->table('cjdb_tags');
__PACKAGE__->columns(Primary => 'id');
__PACKAGE__->columns(All => qw(
	id

	tag

	account
	site
	
	level
	viewing
	
	journals_auth
	
	created
));                                                                                                        
__PACKAGE__->columns(Essential => __PACKAGE__->columns);
__PACKAGE__->sequence('cjdb_tags_id_seq');

__PACKAGE__->has_a('account' => 'CJDB::DB::Accounts');
__PACKAGE__->has_a('journals_auth' => 'CUFTS::DB::JournalsAuth');
__PACKAGE__->has_a('site' => 'CUFTS::DB::Sites');

##
## Returns summary information about tags for a journal:
## [ count, max_level, tag ]
##

sub get_tag_summary {
	my ($class, $journals_auth_id, $site_id, $account_id) = @_;
	my $sth;
	if (defined($account_id)) {
		$sth = $class->sql__tag_summary_with_account;
		$sth->execute($journals_auth_id, $account_id, $site_id);
	} else {
		$sth = $class->sql__tag_summary_without_account;
		$sth->execute($journals_auth_id, $site_id);
	}
	return $sth->fetchall_arrayref;
}

__PACKAGE__->set_sql('_tag_summary_with_account' => qq{
   SELECT COUNT(*) AS count, MAX(level) AS max_level, tag
     FROM __TABLE__
    WHERE journals_auth = ? AND
          account != ? AND
          (
            (
             site = ? AND
             viewing = 2
            )
            OR 
             viewing = 1 
          ) 
 GROUP BY tag
 ORDER BY count, max_level, tag
});

__PACKAGE__->set_sql('_tag_summary_without_account' => qq{
   SELECT COUNT(*) AS count, MAX(level) AS max_level, tag
     FROM __TABLE__
    WHERE journals_auth = ? AND
          (
            (
             site = ? AND
             viewing = 2
            )
            OR 
             viewing = 1 
          ) 
 GROUP BY tag
 ORDER BY count, max_level, tag
});


sub search_taglist_noaccount {
	my ($class, $site, $tag, $offset, $limit) = @_;
	
	$limit  ||= 'ALL';
	$offset ||= 0;
	
	my $sql = qq{
	    SELECT DISTINCT on (tag) tag FROM cjdb_tags 
	    WHERE (    ( site = ?    AND viewing = 2 )
	            OR viewing = 1
	          )
	          AND tag LIKE ?
	    ORDER BY tag
    };

	my $dbh = $class->db_Main();
    my $sth = $dbh->prepare($sql);
	
	$sth->execute($site, $tag);
	my $results = $sth->fetchall_arrayref;
	return $results;
}		

sub search_taglist_account {
	my ($class, $site, $account, $tag, $offset, $limit) = @_;
	
	$limit ||= 'ALL';
	$offset ||= 0;
	
	my $sql = qq{
	    SELECT DISTINCT on (tag) tag FROM cjdb_tags 
	    WHERE (    ( site = ?    AND viewing = 2 )
	            OR ( account = ? AND viewing = 0 )
	            OR viewing = 1
	          )
	          AND tag LIKE ?
	    ORDER BY tag
    };
	my $dbh = $class->db_Main();
    my $sth = $dbh->prepare($sql);
	
	$sth->execute($site, $account, $tag);
	my $results = $sth->fetchall_arrayref;
	return $results;
}		


sub get_mytags_list {
	my ($class, $account_id) = @_;
	my $sth;
	$sth = $class->sql__my_tags;
	$sth->execute($account_id);
	return $sth->fetchall_arrayref;
}

__PACKAGE__->set_sql('_my_tags' => qq{
  SELECT tag, viewing, COUNT(*) AS count
  FROM   __TABLE__
  WHERE  account = ? 
  GROUP  BY tag, viewing
  ORDER  BY tag, viewing
});


1;
