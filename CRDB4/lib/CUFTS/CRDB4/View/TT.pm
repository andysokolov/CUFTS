package CUFTS::CRDB4::View::TT;
use Moose;
use namespace::autoclean;

extends 'Catalyst::View::TT';

__PACKAGE__->config(
    TEMPLATE_EXTENSION => '.tt',
    render_die => 1,
);

$Template::Stash::LIST_OPS->{ in } = sub {
	my ($list, $val, $field) = @_;
	return 0 unless scalar(@$list);
	defined($val) or
		die("Value to match on not passed into 'in' virtual method");

	if (defined($field) && $field ne '') {
		no strict 'refs';
		return((grep { (ref($_) eq 'HASH' ?
		                  $_->{$field} :
				  $_->$field()) eq $val} @$list) ? 1 : 0);
	} else {
		return((grep {$_ eq $val} @$list) ? 1 : 0);
	}
};

$Template::Stash::SCALAR_OPS->{force_list} = sub {
    return [ shift ];
};

$Template::Stash::LIST_OPS->{force_list} = sub {
    return @_;
};

$Template::Stash::HASH_OPS->{force_list} = sub {
    return [ shift ];
};


$Template::Stash::SCALAR_OPS->{substr} = sub { my ($scalar, $offset, $length) = @_; return defined($length) ? substr($scalar, $offset, $length) : substr($scalar, $offset); };
$Template::Stash::SCALAR_OPS->{ceil} = sub { return (int($_[0]) < $_[0]) ? int($_[0] + 1) : int($_[0]) };  # Cheap
$Template::Stash::LIST_OPS->{map_join} = sub {
	my ($list, $field, $join) = @_;
	return join( $join, map { blessed($_) ? $_->$field : $_->{$field} } @$list );
};

$Template::Stash::SCALAR_OPS->{uri_escape} = sub { my $text = shift; $text =~ s/([^a-zA-Z0-9_.-])/uc sprintf("%%%02x",ord($1))/eg; return $text; };

=head1 NAME

CUFTS::CRDB4::View::TT - TT View for CUFTS::CRDB4

=head1 DESCRIPTION

TT View for CUFTS::CRDB4.

=head1 SEE ALSO

L<CUFTS::CRDB4>

=head1 AUTHOR

Todd Holbrook

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
