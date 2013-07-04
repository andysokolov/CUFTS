package CUFTS::CJDB4::View::TT;
use Moose;
use namespace::autoclean;

extends 'Catalyst::View::TT';

__PACKAGE__->config(
    TEMPLATE_EXTENSION => '.tt',
    render_die => 1,
    expose_methods => [qw( option_selected rank_name_sort )],
);


sub option_selected {
	my ( $self, $c, $param, $value ) = @_;
	return (defined($c->request->params->{$param}) && $c->request->params->{$param} eq $value) ? ' selected ' : '';
}

sub rank_name_sort {
	my ( $self, $c, $links, $displays ) = @_;

    my @new_array = sort {
           int( $b->rank || 0 ) <=> int( $a->rank || 0 )
        or $displays->{ $a->get_column('resource') }->{name} cmp $displays->{ $b->get_column('resource') }->{name}
        or ( $a->print_coverage || '' ) cmp ( $b->print_coverage || '' )
        or ( $a->fulltext_coverage || '' ) cmp ( $b->fulltext_coverage || '' )
    } @$links;

    return \@new_array;
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
