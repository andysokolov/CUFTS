package CUFTS::CJDB4::View::TT;
use Moose;
use namespace::autoclean;

extends 'Catalyst::View::TT';

__PACKAGE__->config(
    TEMPLATE_EXTENSION => '.tt',
    ENCODING => 'utf-8',
    render_die => 1,
    expose_methods => [qw( option_selected )],
);

sub option_selected {
	my ( $self, $c, $param, $value ) = @_;
	return (defined($c->request->params->{$param}) && $c->request->params->{$param} eq $value) ? ' selected ' : '';
}


=head1 NAME

CUFTS::CJDB4::View::TT - TT View for CUFTS::CJDB4

=head1 DESCRIPTION

TT View for CUFTS::CJDB4.

=head1 SEE ALSO

L<CUFTS::CJDB4>

=head1 AUTHOR

Todd Holbrook

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
