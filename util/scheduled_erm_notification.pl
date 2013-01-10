#!/usr/local/bin/perl

##
## This script checks all CUFTS sites for files that are
## marked for reloading.
##

use lib qw(lib);

use CUFTS::Exceptions;
use CUFTS::Config;
use CUFTS::DB::Resources;
use CUFTS::DB::Sites;
use CUFTS::DB::ERMMain;
use Net::SMTP;
use DateTime;
use DateTime::Format::Pg;
use Getopt::Long;
use String::Util qw(hascontent);

use strict;

my $now     = DateTime->now;
my $now_ymd = $now->ymd;

my %options;
GetOptions( \%options, 'site_key=s', 'site_id=i' );

my $site_iter;
if ( $options{site_id} ) {
    $site_iter = CUFTS::DB::Sites->search( id => int($options{site_id}) );
}
elsif ( $options{site_key} ) {
    $site_iter = CUFTS::DB::Sites->search( key => $options{site_key} );
}
else {
    $site_iter = CUFTS::DB::Sites->retrieve_all;
}


while (my $site = $site_iter->next) {
    print "Checking " . $site->name . "\n";
    my $site_notice = undef;

    my $site_email = $site->erm_notification_email || $site->email;
    if (!defined($site_email)) {
      warn('A site or ERM notification email must be set for: ' . $site->name . ' to send out ERM notifications. Skipping site.');
      next;
    }

    my @resources = CUFTS::DB::ERMMain->search( 'site' => $site->id );
    my %emails;
    foreach my $resource (@resources) {

        # Check alert expiries
        if ( $resource->alert_expiry ) {
            my $alert_expiry_date = DateTime::Format::Pg->parse_date( $resource->alert_expiry );
            if ( $alert_expiry_date->ymd le $now_ymd ) {
            	my $alert = $resource->alert();
                $resource->alert(undef);
                $resource->alert_expiry(undef);
                $resource->update();
                $emails{$site_email} .= 'Expired alert notice for: ' . $resource->key . ":\n$alert\n";
            }
        }
        
        if ( $resource->renewal_notification && $resource->contract_end ) {
            my $rn_days = int($resource->renewal_notification);
            my $end     = DateTime::Format::Pg->parse_date( $resource->contract_end );

            my $rn_date = $end->clone->add( days => -$rn_days );
            if ( $rn_date->ymd eq $now->ymd ) {
                my $erm_email = $resource->notification_email || $site_email;
                $emails{$erm_email} .= 'Renewal notification for: ' . $resource->key . '. Contract expires: ' . $end->ymd . "\n";
            }
        }

        if ( hascontent($resource->marc_schedule) && $resource->marc_schedule eq $now->ymd ) {
            my $erm_email = $resource->marc_alert || $site_email;
            $emails{$erm_email} .= 'Check for downloadable MARC records for: ' . $resource->key . "\n";
            
            if ( my $interval = int($resource->marc_schedule_interval) ) {
                my $new_date = $now->clone->add( months => $interval );
                $resource->marc_schedule($new_date->ymd);
                $resource->update();
            }
        }

    }

    next if ( !scalar(%emails) );


    foreach my $email_address ( keys(%emails) ) {

        my $message = $emails{$email_address};

        warn(" * Sending notification to: $email_address\n$message\n");

        my $host = defined($CUFTS::Config::CUFTS_SMTP_HOST) ? $CUFTS::Config::CUFTS_SMTP_HOST : 'localhost';
        my $smtp = Net::SMTP->new($host);
        
        if ( !defined($smtp) ) {
            warn(' * Unable to create SMTP object for mailing');
            next;
        }

        $smtp->mail($CUFTS::Config::CUFTS_MAIL_FROM);
        $smtp->to(split /\s*,\s*/, $email_address);
        $smtp->data();
        $smtp->datasend("To: $email_address\n");
        $smtp->datasend("Subject: CUFTS ERM Notifications\n");
        defined($CUFTS::Config::CUFTS_MAIL_REPLY_TO) and
          $smtp->datasend("Reply-To: ${CUFTS::Config::CUFTS_MAIL_REPLY_TO}\n");
        $smtp->datasend("\n");
        $smtp->datasend("CUFTS ERM Notifications for " . $now->ymd . "\n");
        $smtp->datasend($message);
        $smtp->dataend();
        $smtp->quit();

        warn(" * Notice sent.\n");

    }


    CUFTS::DB::DBI->dbi_commit();

    print "Finished ", $site->name,  "\n";
}   

    


