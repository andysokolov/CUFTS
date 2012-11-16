package Class::DBI::CUFTS::MaintTool::FromForm;

use strict;
use vars qw/$VERSION @EXPORT/;
use base 'Exporter';

$VERSION = 0.03;

@EXPORT = qw/update_from_form create_from_form/;

=head1 NAME

Class::DBI::FromForm - Update Class::DBI data using Data::FormValidator

=head1 SYNOPSIS

  package Film;
  use Class::DBI::FromForm;
  use base 'Class::DBI';

  my $results = Data::FormValidator->check( ... );
  my $film = Film->retrieve('Fahrenheit 911');
  $film->update_from_form($results);

  my $new_film = Film->create_from_form($results);

=head1 DESCRIPTION

Create and update L<Class::DBI> objects from L<Data::FormValidator>.

=head2 METHODS

=head3 create_from_form

Create a new object.

=cut

sub create_from_form {
    my $class = shift;
    die "create_from_form can only be called as a class method" if ref $class;
    __PACKAGE__->_run_create( $class, @_ );
}

=head3 update_from_form

Update object.

=cut

my %column_handler = (
	16 => \&handle_boolean,
);

sub update_from_form {
    my $self = shift;
    die "update_from_form cannot be called as a class method" unless ref $self;
    __PACKAGE__->_run_update( $self, @_ );
}

##
## Two stage creation - one to create the base object and the second to handle
## any details columns.
##

sub _run_create {
	my ( $me, $class, $results ) = @_;
	my $them = bless {}, $class;
	my $data = $results->valid;
	my $cols = {};
	
	foreach my $col ( $class->columns('All') ) {
		my $val = $data->{$col};
		
		next unless defined($val);

		if ($class->can('column_type')) {
			my $col_type = $class->column_type($col);
			defined($col_type) && exists($column_handler{$col_type}) and
				$val = &{$column_handler{$col_type}}($val);
		}
			
		$cols->{$col} = $val;
		delete $data->{$col};
	}
	
	my $obj = $class->create($cols);

	foreach my $col ( keys %$data ) {
		if ( $obj->can($col) ) {
			next if $col eq $obj->primary_column;
			my $val = $data->{$col};

			if ($obj->can('column_type')) {
				my $col_type = $obj->column_type($col);
				defined($col_type) && exists($column_handler{$col_type}) and
					$val = &{$column_handler{$col_type}}($val);
			}
			
			$obj->$col($val);
		}
	}

	$obj->update;
	return $obj;
}

sub _run_update {
	my ( $me, $them, $results ) = @_;

	foreach my $col ( keys %{ $results->valid } ) {

		if ( $them->can($col) ) {
			next if $col eq $them->primary_column;
			my $val = $results->valid($col);

			if ($them->can('column_type')) {
				my $col_type = $them->column_type($col);
				defined($col_type) && exists($column_handler{$col_type}) and
					$val = &{$column_handler{$col_type}}($val);
			}
			
			$them->$col($val);
		}
	}

	$them->update;
	return $them;
}

sub handle_boolean {
	my $val = shift;
	my ($true, $false) = ('true', 'false');
	return $false unless defined($val);
	return $false if $val eq '';
	
	if ($val eq 't' ||
	    $val eq 'true' ||
	    $val eq '1' ||
	    $val eq 'on' ||
	    $val eq 'yes') {
	    	return $true;
	} elsif ($val eq 'f' ||
	         $val eq 'false' ||
	         $val eq '0' ||
	         $val eq 'off' ||
	         $val eq 'no') {
	         return $false;
	} elsif ($val =~ /^-?\d+\.?\d*$/) {
		return int($val) ? $true : $false;
	} else {
		die("Unable to interpret boolean variable value: $val");
	}
}






=head1 SEE ALSO

L<Class::DBI>, L<Class::DBI::FromCGI>, L<Data::FormValidator>

=head1 AUTHOR

Sebastian Riedel, C<sri@oook.de>

=head1 LICENSE

This library is free software . You can redistribute it and/or modify it under
the same terms as perl itself.

=cut

1;
