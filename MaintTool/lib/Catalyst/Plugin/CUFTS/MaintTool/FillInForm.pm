package Catalyst::Plugin::CUFTS::MaintTool::FillInForm;

use strict;
use NEXT;
use HTML::FillInForm;

our $VERSION = '0.04';

=head1 NAME

Catalyst::Plugin::FillInForm - FillInForm for Catalyst

=head1 SYNOPSIS

    use Catalyst 'FillInForm';

    $c->fillform;

=head1 DESCRIPTION

Fill forms automatically.

=head2 EXTENDED METHODS

=head3 finalize

Will automatically fill in forms if the last form has missing/
invalid fields.

=cut

sub finalize {
    my $c = shift;
    if ( $c->can('form') ) {
        $c->fillform
          if $c->form->has_missing
          || $c->form->has_invalid
          || $c->stash->{error}
          || $c->stash->{errors};
    }
    return $c->NEXT::finalize(@_);
}

=head2 METHODS

=head3 fillform

Fill form based on request parameters.

=cut

sub fillform {
	my $c = shift;
	my $fdat = $c->req->params;
	my $valid = $c->form->valid;

	foreach my $field (keys %$valid) {
		!exists($fdat->{$field}) && exists($valid->{$field}) and
			$fdat->{$field} = '';
	}
	if ($c->debug) {
		use Data::Dumper;
		my $output = "Data being passed to FormFill is\n--------------------\n" . Dumper($fdat) . "\n--------------------\n";
		$c->log->debug($output);
	}
	
	$c->response->output(
		HTML::FillInForm->new->fill(
		scalarref => \$c->res->{body},
		fdat      => $fdat,
		)
	);
}

=head1 SEE ALSO

L<Catalyst>, L<HTML::FillInForm> .

=head1 AUTHOR

Sebastian Riedel, C<sri@cpan.org>
Marcus Ramberg, C<mramberg@cpan.org>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
