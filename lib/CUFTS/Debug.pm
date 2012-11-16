## CUFTS::Debug
##
## Copyright Todd Holbrook (2003)
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

# Contains various commands for exporting which handle debug, warning, error
# messages, etc.  Prints to STDERR, might be modified to send to a log file.


package CUFTS::Debug;

use Exporter ();
@ISA = qw( Exporter );
@EXPORT = qw(
	debug
	error
	warning
	send_admin_email
	report_location
);

@EXPORT_OK = qw(
	debug
	error
	warning
	report_location
);

use CGI qw(:standard -oldstyle_urls);
use strict;

sub debug {
	print STDERR (join '', 'Debug: ', @_, "\n");
}

sub warning {
	print STDERR (join '', 'Warning: ', @_, "\n");
}

sub error {
	print STDERR (join '', 'Error: ', @_, "\n");
}

sub report_location {
	my ($pack, $file, $link, $subname, $hasargs, $wantarray) = caller(1);
	print STDERR "Trace: $subname\n";
}


sub send_admin_email {
    my($to, $message) = @_; 
    local(*SENDMAIL);
    my($subject);   

    $subject = "Message from CUFTS (debug)"; 
    my($sendmail) = '/usr/lib/sendmail -t -n';
    $message = "\n\nremote_host: " . &CGI::remote_host  . "\n\nreferer: " . &CGI::referer . "\n\n" . $message;
    open (SENDMAIL, "| $sendmail") || return;
    print SENDMAIL <<End_of_Message;
From: 
To: $to
Reply-To:
Subject: $subject

$message
End_of_Message

    close(SENDMAIL);
}

1;

__END__

=head1 NAME

CUFTS::Debug - Debug routines for the CUFTS system

=head1 METHODS

=over 4

=item debug($message)

=item warning($message)

=item error($message)

All these routines write I<$message> to STDERR.

=item send_admin_email($maillist, $message)

Sends I<$message> by email to the recipients specified by
I<$to>.


=back

=cut