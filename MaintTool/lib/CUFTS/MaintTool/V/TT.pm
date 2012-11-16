package CUFTS::MaintTool::V::TT;

use strict;
#use Template::Config;
#$Template::Config::STASH = 'Template::Stash::XS';

use base 'Catalyst::View::TT';

use CUFTS::CJDB::Util;

__PACKAGE__->config->{WRAPPER} = 'layout.tt';
__PACKAGE__->config->{FILTERS} = {
    'marc8'   => \&CUFTS::CJDB::Util::marc8_to_latin1,
    'js_data' => \&js_data_filter,
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

$Template::Stash::LIST_OPS->{ simple_difference } = sub {
	my ($a, $b) = @_;
	my (%seen, @aonly);
	
	@seen{@$b} = ();  # build lookup table

	foreach my $item (@$a) {
		push(@aonly, $item) unless exists $seen{$item};
	}
	
	return \@aonly;
};

$Template::Stash::LIST_OPS->{ map_join } = sub {
    my ( $list, $field, $join_sep ) = @_;
    return join $join_sep, map {$_->$field} @$list;
};

$Template::Stash::SCALAR_OPS->{substr} = sub { my ($scalar, $offset, $length) = @_; return defined($length) ? substr($scalar, $offset, $length) : substr($scalar, $offset); };
$Template::Stash::SCALAR_OPS->{ceil} = sub { return (int($_[0]) < $_[0]) ? int($_[0] + 1) : int($_[0]) };  # Cheap


sub js_data_filter {
    my $text = shift;
    $text =~ s{'}{\\'}g;
    $text =~ s{\r?\n}{\\n}g;
    return $text;
}


=head1 NAME

CUFTS::MaintTool::V::TT - TT View Component

=head1 SYNOPSIS

    Very simple to use

=head1 DESCRIPTION

Very nice component.

=head1 AUTHOR

Clever guy

=head1 LICENSE

This library is free software . You can redistribute it and/or modify it under
the same terms as perl itself.

=cut

1;
