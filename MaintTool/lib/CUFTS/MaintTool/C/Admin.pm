package CUFTS::MaintTool::C::Admin;

use strict;
use base 'Catalyst::Base';

sub auto : Private {
	my ($self, $c) = @_;

	# Everything in this controller should be accessible only to admins
	
	$c->stash->{current_account}->administrator or 
		die('User not authorized for access to administration functions');

    $c->stash->{header_section} = 'Administration';

	return 1;
}

sub default : Private {
	my ($self, $c) = @_;
	$c->stash->{template} = 'admin/menu.tt';
}


=head1 NAME

CUFTS::MaintTool::C::Admin - A Component

=head1 SYNOPSIS

    Very simple to use

=head1 DESCRIPTION

Very nice component.

=head1 AUTHOR

A clever guy

=head1 LICENSE

This library is free software . You can redistribute it and/or modify 
it under the same terms as perl itself.

=cut

1;

