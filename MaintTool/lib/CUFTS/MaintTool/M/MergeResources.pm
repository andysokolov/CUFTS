##
## CDBI-style resource for holding a merged record.
##

package CUFTS::DB::MergedResource;

use strict;

use Class::Accessor;
use base qw(Class::Accessor);

__PACKAGE__->mk_accessors(qw/
	name
	provider
	resource_type
	module
	rank
	title_list_scanned
	active
	local
	global
/);

	
sub new {
	my $class = shift;

	my $self = bless {}, $class;

	no strict 'refs';
	while (scalar(@_)) {
		my ($key, $val) = (shift, shift);
		$self->$key($val);
	}	

	return $self;
}

##
## Model code for creating the merged record above
## 

package CUFTS::MaintTool::M::MergeResources;

use strict;

use base 'Catalyst::Base';

sub merge {
	my ($class, $local_arr, $global_arr, $active) = @_;

	my (@resources, %local);

	foreach my $local (@$local_arr) {
		next if $active && !$local->active;

		if ($local->resource) {
			$local{$local->resource} = $local;
		} else {
			push @resources, CUFTS::DB::MergedResource->new(
				'name'			=> $local->name,
				'provider'		=> $local->provider,
				'resource_type'		=> $local->resource_type,
				'module'		=> $local->module,
				'rank'			=> $local->rank,
				'title_list_scanned'	=> $local->title_list_scanned,
				'active'		=> $local->active,
				'local' 		=> $local,
			);
		}
	}

	foreach my $global (@$global_arr) {
		my $local = $local{$global->id};

		next if !defined($local) && $active;
		next if $active && !$local->active;

		my $resource = CUFTS::DB::MergedResource->new(
			'name'			=> $global->name,
			'provider'		=> $global->provider,
			'resource_type'		=> $global->resource_type,
			'module'		=> $global->module,
			'title_list_scanned'	=> $global->title_list_scanned,
			'active'		=> 0,
			'global' 		=> $global,
		);
	
		if (defined($local)) {
			$resource->active($local->active);
			$resource->rank($local->rank);
			$resource->local($local);
		}

		push @resources, $resource;
	}

	return \@resources;
}





1;