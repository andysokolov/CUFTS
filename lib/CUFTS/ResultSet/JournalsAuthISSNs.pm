package CUFTS::ResultSet::JournalsAuthISSNs;

use strict;
use base 'DBIx::Class::ResultSet';

sub search_issn {
    my ( $self, $issn ) = @_;
    return $self->search({ issn => _clean_issn($issn) }, @_);
}

sub find_or_create {
	my $self     = shift;
	my $attrs    = (@_ > 1 && ref $_[$#_] eq 'HASH' ? pop(@_) : {});
	my $hash     = ref $_[0] eq 'HASH' ? shift : {@_};

	if ( exists $hash->{issn} && !ref $hash->{issn} ) {
		$hash->{issn} = _clean_issn($hash->{issn});
	}

	return $self->next::method($hash, $attrs);
}

sub _clean_issn {
	my $issn = uc(shift);
    $issn =~ tr/0-9X//cd;
    return $issn;
}


1;