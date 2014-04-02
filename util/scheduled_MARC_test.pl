#!/usr/local/bin/perl

##
## This script checks all CUFTS sites for files that are
## marked for reloading.
##

use lib qw(lib);

use CUFTS::Exceptions;
use CUFTS::Config;
use Net::SMTP;
use String::Util qw(hascontent trim);

use strict;

my $schema = CUFTS::Config::get_schema();

my $site_rs = $schema->resultset('Sites');
while (my $site = $site_rs->next) {
    print "Checking " . $site->name . "\n";

    next unless defined $site->test_MARC_file;

	if ( !defined $site->email ) {
        warn('Test scheduled for ' . $site->name . ', but email address is not defined');
        next;
    }

    my @files = split /\|/, $site->test_MARC_file;
    my $site_id = $site->id;
    my $email = $site->email;

    foreach my $filename (@files) {
        print "Testing file: $filename\n";

        my $file = $CUFTS::Config::CJDB_SITE_DATA_DIR . '/' . $site_id . '/' . $filename;

        my $results;
        open RESULTS, "util/MARC_file_checker.pl $file |";
        while (<RESULTS>) {
            $results .= $_;
        }

        # Mail results

        my $host = defined($CUFTS::Config::CUFTS_SMTP_HOST) ? $CUFTS::Config::CUFTS_SMTP_HOST : 'localhost';
        my $smtp = Net::SMTP->new($host);
        $smtp->mail($CUFTS::Config::CUFTS_MAIL_FROM);
        $smtp->to(split /\s*,\s*/, $email);
        $smtp->data();
        $smtp->datasend("To: $email\n");
        $smtp->datasend("Subject: MARC file test for file $filename\n");
        defined($CUFTS::Config::CUFTS_MAIL_REPLY_TO) and
            $smtp->datasend("Reply-To: ${CUFTS::Config::CUFTS_MAIL_REPLY_TO}\n");
        $smtp->datasend("\n");
        $smtp->datasend($results);
        $smtp->dataend();
        $smtp->quit();
    }

    $site->set('test_MARC_file', undef);
    $site->update;
    $site->dbi_commit;

    print "Finished ", $site->name,  "\n";
}
