#============================================================= -*-Perl-*-
#
# Template::Plugin::MinMax
#
# DESCRIPTION
#   Template Toolkit plugin to implement min() and max() functions
#
# AUTHOR
#   Todd Holbrook <tholbroo@sfu.ca>
#
# COPYRIGHT
#   Copyright (C) 2005 Todd Holbrook.  All Rights Reserved.
#
#   This module is free software; you can redistribute it and/or
#   modify it under the same terms as Perl itself.
#
# REVISION
#   $Id: MinMax.pm,v 2.34 2004/01/30 19:33:20 abw Exp $
#
#============================================================================

package Template::Plugin::MinMax;

require 5.004;

use strict;
use Template::Plugin;

use base qw( Template::Plugin );
use vars qw( $VERSION $ERROR);

$VERSION = sprintf("%d.%02d", q$Revision: 0.01 $ =~ /(\d+)\.(\d+)/);
$ERROR   = '';

#------------------------------------------------------------------------

sub load {
	my ($class, $context) = @_;
	return $class;
}

sub new {
    my ($self, $context, @args) = @_;
    return bless { _CONTEXT => $context }, $self;
}

sub min {
	my ($self, @args) = @_;
	
	my $min = shift @args;
	while (my $val = shift @args) {
		$val < $min and
			$min = $val;
	}

	return $min;
}

sub max {
	my ($self, @args) = @_;
	
	my $max = shift @args;
	while (my $val = shift @args) {
		$val > $max and
			$max = $val;
	}
	
	return $max;
}

sub int {
	my ($self, @args) = @_;
	my $int = shift @args;

	return int($int);
}

1;

__END__

=head1 AUTHOR

Todd Holbrook E<lt>tholbroo@.sfuE<gt>

=head1 VERSION

0.01

=head1 COPYRIGHT

  Copyright (C) 2005 Todd Holbrook.  All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Template::Plugin|Template::Plugin>

=cut

