package CUFTS::MaintTool4::View::TT;

use strict;
use warnings;

use base 'Catalyst::View::TT';

use String::Util qw(hascontent);

__PACKAGE__->config(
    TEMPLATE_EXTENSION => '.tt',
    render_die => 1,
);


# Expose String::Util hascontent()
$Template::Stash::SCALAR_OPS->{ hascontent } = sub {
  return hascontent(shift @_);
};
$Template::Stash::HASH_OPS->{ hascontent } = sub {
    my $hash = shift @_;
    return defined($hash) && scalar(keys(%$hash));
};
$Template::Stash::LIST_OPS->{ hascontent } = sub {
    my $list = shift @_;
    return defined($list) && scalar($list);
};


$Template::Stash::HASH_OPS->{ in } = sub {
  return __in( [ shift @_ ], @_ );
};

$Template::Stash::SCALAR_OPS->{ in } = sub {
  return __in( [ shift @_ ], @_ );
};


$Template::Stash::LIST_OPS->{ in } = \&__in;

sub __in {
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
}

=head1 NAME

CUFTS::MaintTool4::View::TT - TT View for CUFTS::MaintTool4

=head1 DESCRIPTION

TT View for CUFTS::MaintTool4.

=head1 SEE ALSO

L<CUFTS::MaintTool4>

=head1 AUTHOR

tholbroo

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
