use strict;
use lib 'lib';

use CUFTS::Config;
use CUFTS::Schema;
use Term::ReadLine;
use Getopt::Long;

my $schema = CUFTS::Schema->connect( $CUFTS::Config::CUFTS_DB_STRING, $CUFTS::Config::CUFTS_USER, $CUFTS::Config::CUFTS_PASSWORD );
my $term = new Term::ReadLine 'CUFTS Site Cleanup';

my @tables = qw(
	CJDBJournalsAssociations
	CJDBJournalsSubjects
	CJDBJournalsTitles
	CJDBRelations
	CJDBISSNs
	CJDBLinks
	CJDBJournals
	Stats
);


my %options;
GetOptions( \%options, 'site_key=s', 'site_id=i' );

my $site_search =   $options{site_id}   ? { id => int($options{site_id}) }
                  : $options{site_key}  ? { key => $options{site_key} }
                  : {};
my $site = $schema->resultset('Sites')->find($site_search);

print "Clearing data for site: ", $site->name, "\n";
my $input = $term->readline('Confirm [y/N]: ');
exit unless $input =~ /^\s*y/i;

foreach my $table ( @tables ) {
	my $rs = $schema->resultset($table)->search({site => $site->id});
	print "Deleting from table $table: ", $rs->count, "\n";
	$rs->delete;
}

my $cjdb_accounts = $schema->resultset('CJDBAccounts')->search({site => $site->id});
print "Deleting from table CJDBAccounts and Roles: ", $cjdb_accounts->count, "\n";
while ( my $account = $cjdb_accounts->next ) {
	$schema->resultset('CJDBAccountsRoles')->search({account => $account->id})->delete;
	$account->delete;
}

my $local_resources = $schema->resultset('LocalResources')->search({ site => $site->id });
print "Deleting from table LocalResources and attached journals: ", $local_resources->count, "\n";
while ( my $local_resource = $local_resources->next ) {
	$schema->resultset('LocalJournals')->search({ resource => $local_resource->id })->delete;
	$local_resource->delete;
}

print "Done with site.\n";
