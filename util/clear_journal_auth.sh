#!/bin/tcsh

echo 'You have 10 seconds to abort this...'
sleep 10

echo 'delete from cjdb_subjects' | psql $1
echo 'delete from cjdb_links' | psql $1
echo 'delete from cjdb_journals' | psql $1
echo 'delete from cjdb_associations' | psql $1
echo 'delete from cjdb_titles' | psql $1
echo 'delete from cjdb_issns' | psql $1
echo 'delete from cjdb_tags' | psql $1
echo 'delete from journals_auth_titles' | psql $1
echo 'delete from journals_auth_issns' | psql $1
echo 'delete from journals_auth' | psql $1
echo 'update journals set journal_auth = NULL where journal_auth IS NOT NULL' | psql $1
echo 'update local_journals set journal_auth = NULL where journal_auth IS NOT NULL' | psql $1
echo 'vacuum analyze' | psql $1
