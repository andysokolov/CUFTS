package Catalyst::Plugin::CUFTS::MaintTool::FormValidator;

use strict;
use NEXT;
use Data::FormValidator;

our $VERSION = '0.02';

=head1 NAME

Catalyst::Plugin::FormValidator - FormValidator for Catalyst

=head1 SYNOPSIS

    use Catalyst 'FormValidator';

    $c->form( optional => ['rest'] );
    print $c->form->valid('rest');

=head1 DESCRIPTION

This plugin uses L<Data::FormValidator> to validate and set up form data
from your request parameters. It's a quite thin wrapper around that
module, so most of the relevant information can be found there.

=head2 EXTENDED METHODS

=head3 prepare

Sets up $c->{form}
=cut

sub prepare {
    my $c = shift;
    $c = $c->NEXT::prepare(@_);
    $c->{form} = Data::FormValidator->check( $c->request->parameters, {} );
    return $c;
}

=head2 METHODS

=head3 form

Merge values with FormValidator.

    $c->form( required => ['yada'] );

Returns a L<Data::FormValidator::Results> object.

    $c->form->valid('rest');

The actual parameters sent to $c->form are the same as used by
L<Data::FormValidator>'s check function.

=cut

sub form {
    my $c = shift;
    if ( $_[0] ) {
        my $form = $_[1] ? {@_} : $_[0];
        $c->{form} =
          Data::FormValidator->check( $c->request->parameters, $form );
	  
	  # Fix checkboxes
	  
	  if ($form->{missing_optional_valid}) {
	  	my $valid = $c->{form}->valid;
	  	foreach my $field (@{$form->{optional}}) {
	  		exists($valid->{$field}) or
	  			$c->{form}->{valid}->{$field} = undef;
	  	}
	  }


    }
    return $c->{form};
}

=head1 SEE ALSO

L<Catalyst>, L<Data::FormValidator>

=head1 AUTHOR

Sebastian Riedel, C<sri@cpan.org>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
