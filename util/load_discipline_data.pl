#!/usr/local/bin/perl

use lib 'lib';

use CUFTS::DB::Resources;
use CJDB::DB::Journals;
use CJDB::DB::Tags;
use CJDB::DB::Accounts;
use CJDB::DB::ISSNs;

use CUFTS::CJDB::Util;
use CUFTS::Util::Simple;

use Getopt::Long;

use strict;

my %options;
GetOptions( \%options, 'site_key=s', 'site_id=i', 'create_accounts' );
my @files = @ARGV;

if ( $options{site_key} || $options{site_id} ) {
    my $site = get_site();
    load_site( $site, @files );
}
else {
    usage();
}


sub load_site {
    my ( $site, @files ) = @_;

    my %accounts;
    foreach my $account ( CJDB::DB::Accounts->search( site => $site->id ) ) {
    	$accounts{$account->key} = $account->id;
    }

    foreach my $file (@files) {

    	open INPUT, $file or 
    		die "Unable to open input file: $!";

LINE:
    	while (<INPUT>) {

        	my ($name, $tags, $issns) = split /\t/, $_, 3;
        	my @issns = split /[\t;]/, $issns;

        	$name  = trim_string($name, '"');
        	$tags  = trim_string($tags, '"');
        	$issns = trim_string($issns);
        	
    	    next LINE if is_empty_string($name);
    	    next LINE if is_empty_string($tags);

            print "$name, $tags, $issns\n";

            my $account_id = $accounts{$name};
            if ( !defined($account_id) ) {

                if ( $options{create_accounts} ) {

                    my $account;
                    eval {
                        $account = CJDB::DB::Accounts->create({
                            site   => $site->id,
                            key    => $name,
                            active => 't',
                        });
                    };

                    if ($@ || !defined($account) ) {
                        CUFTS::DB::DBI->dbi_rollback();
                        die("Error creating account: $@");
                    }
                    $account_id = $account->id;
                    $accounts{$name} = $account_id;
                    print "Created account: $name  --  id: $account_id\n";

                } else {
                    print "Unrecognized account name: $name.  Skipping.\n";
                    next LINE;
                }

            }
	
        	my @tags = split /,/, $tags;
        	foreach my $x (0 .. $#tags) {
        		$tags[$x] = CUFTS::CJDB::Util::strip_tag($tags[$x]);
        	}
	
        	my %seen;
        	foreach my $issn (@issns) {
        		$issn = trim_string( uc($issn) );
        		$issn =~ s/-//;
		
        		next if !defined($issn);
        		next if $issn !~ /\d{7}[\dX]/;

        		next if $seen{$issn}++;
		
        		my @issn_records = CJDB::DB::ISSNs->search('site' => $site->id, 'issn' => $issn);
        		foreach my $issn_record (@issn_records)	{
        			foreach my $tag (@tags) {

        				CJDB::DB::Tags->find_or_create({
        					site => $site->id,
        					account => $account_id,
        					tag => $tag,
        					level => 100,
        					viewing => 1,
        					journals_auth => $issn_record->journal->journals_auth->id,
        				});
        			}
        		}

        	}
        }
    }

    CJDB::DB::DBI->dbi_commit;
}


sub get_site {
    defined( $options{'site_id'} )
        and return CUFTS::DB::Sites->retrieve( int( $options{'site_id'} ) );

    my @sites = CUFTS::DB::Sites->search( 'key' => $options{'site_key'} );

    scalar(@sites) == 1
        or die( 'Could not get CUFTS site for key: ' . $options{'site_key'} );

    return $sites[0];
}


sub usage {
    print "load_discipline_data.pl - loads tab delimited list of tags\n";
    
}