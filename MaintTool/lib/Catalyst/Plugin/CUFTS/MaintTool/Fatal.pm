package Catalyst::Plugin::CUFTS::MaintTool::Fatal;

use strict;
use NEXT;

our $VERSION = '0.01';

=head1 NAME

Catalyst::Plugin::CUFTS::MaintTool::Fatal - Fatal error handling for Catalyst

=head1 SYNOPSIS

	use Catalyst 'Fatal';
	

	sub do_something : Local {
		my ($self, $c) = @_;

		# Do something
	
		if ($something_bad_happened) {
			return $c->fatal('Something bad happened');
		}
		
		# ...

	}

=head1 DESCRIPTION

This plugin creates a fatal() method in the context variable.  This accepts
a list of error messages to and logs them through error().  It puts the
messages into the stash, sets forward, clears $c->req->action, and returns
0.  This allows you to report errors while keeping the user in the
application display.

=head2 METHODS

=over 4

=item fatal

Logs fatal errors and passes them on to a template to be reported to the user.

    $c->fatal('Something bad happened', 'Something worse happened');

=cut

sub fatal {
	my ($c, @errors) = @_;
	
	my $stash_prefix = $c->config->{fatal}->{stash_prefix} || 'fatal';
	my $forward = $c->config->{fatal}->{forward} || 'end';

	# Put template and errors into stash

	defined($c->config->{fatal}->{template}) and 
		$c->stash->{template} = $c->config->{fatal}->{template};

	$c->stash->{"${stash_prefix}_errors"} = \@errors;

	# Gather caller info
	
	my ($package, $filename, $line, $subname, $hasargs, $wantarray) = caller(1);
	$c->stash->{"${stash_prefix}_report"} = "Fatal error(s) in $package::$subname line $line";
	$c->stash->{"${stash_prefix}_package"} = $package;
	$c->stash->{"${stash_prefix}_filename"} = $filename;
	$c->stash->{"${stash_prefix}_line"} = $line;
	$c->stash->{"${stash_prefix}_subname"} = $subname;
	$c->stash->{"${stash_prefix}_hasargs"} = $hasargs;
	$c->stash->{"${stash_prefix}_wantwarray"} = $wantarray;

	# Log caller info

	$c->log->error($c->stash->{"${stash_prefix}_report"});

	# Log individual errors

	foreach my $error (@errors) {
		$c->log->error($error);
	}

	# Unless "no_dump" is true, include a Data::Dumper dump of $c

	unless ($c->config->{fatal}->{no_dump}) {
		use Data::Dumper;
		$c->stash->{"${stash_prefix}_dump"} = Dumper($c);
		$c->log->error($c->stash->{"${stash_prefix}_dump"});
	}

	# Unless "no_clear_action" is true, clear the request action so we can
	# get out of auto/begin actions properly

	$c->config->{fatal}->{no_clear_action} or
		$c->req->action(undef);
		
	# Forward to another action if configured.  This allows further tweaking
	# of the stash, or handling the report another way if the "end" action
	# will not display the errors

	$c->config->{fatal}->{no_forward} or
		$c->forward($forward);

	return 0;
}

1;
		
	
