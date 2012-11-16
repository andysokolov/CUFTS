package CUFTS::MaintTool::C::Site;

use strict;
use base 'Catalyst::Base';

use CUFTS::Util::Simple;

my $edit_form_validate = {
	required => ['name'],
	optional => ['email', 'erm_notification_email', 'proxy_prefix', 'proxy_prefix_alternate', 'proxy_WAM', 'show_ERM', 'submit', 'cancel'],
	filters  => ['trim'],
	missing_optional_valid => 1,
};

my $ips_form_validate = {
	optional => ['submit', 'cancel', 'domainnew', 'ip_low_new','ip_high_new'],
	optional_regexp => qr/^(ip|domain)/,
	filters => ['trim'],
	constraint_regexp_map => {
		qr/^ip_low_/   => qr/^\d+\.\d+\.\d+\.\d+/,
		qr/^ip_high_/  => qr/^\d+\.\d+\.\d+\.\d+/,
		qr/^domain\d+/ => qr/^[-\w\.]+$/,  # /
	},
};

sub auto : Private {
	my ($self, $c) = @_;
    $c->stash->{header_section} = 'Site Settings';
    return 1;
}

sub change : Local {
	my ($self, $c) = @_;
	
	$c->form({optional => ['change_site', 'cancel', 'submit']});

	# Check for cancel button

	$c->form->valid->{cancel} eq 'cancel' and
		return $c->forward('/main');	

	# Build list of sites used for both display and confirmation of
	# access to chosen site
	
	my @site_list;
	if ($c->stash->{current_account}->administrator) {
		@site_list = CUFTS::DB::Sites->retrieve_all;
	} else {
		@site_list = $c->stash->{current_account}->sites;
	}

	# Filter out sites athat are not active
	@site_list = grep { $_->active } @site_list;

	if ($c->form->valid->{'change_site'}) {

		# Change the site if this is a submission.  Check to make sure the user
		# isn't trying to switch to a site they don't have access to

		my @check_list = grep {$_->id == int($c->form->valid->{'change_site'})} @site_list;
		if (scalar(@check_list) == 1) {
			$c->stash->{current_site} = $check_list[0];
			$c->session->{current_site_id} = $check_list[0]->id;
			return $c->forward('/main');
		} else {	
			$c->stash->{'errors'} = ["You do not have permission to change to that site."];
		}
	}

	# Display a list of sites

	$c->stash->{sites} = \@site_list;
    $c->stash->{header_section} = 'Change Site';
    $c->stash->{template} = 'site/change.tt';
}

sub edit : Local {
	my ($self, $c) = @_;

	$c->req->params->{cancel} and
		return $c->redirect('/main');
	
	if ($c->req->params->{submit}) {
		$c->form($edit_form_validate);
	
		unless ($c->form->has_missing || $c->form->has_invalid || $c->form->has_unknown) {
		
			eval {
				$c->stash->{current_site}->update_from_form($c->form);
			};
			if ($@) {
				my $err = $@;
				CUFTS::DB::DBI->dbi_rollback;
				die($err);
			}
			
			CUFTS::DB::DBI->dbi_commit;
			push @{$c->stash->{results}}, 'Site data updated.';
		}
	}
	
	$c->stash->{section} = 'general';
	$c->stash->{template} = 'site/edit.tt';
}

sub ips : Local {
	my ($self, $c) = @_;

	$c->req->params->{cancel} and
		return $c->redirect('/site/edit');
	
	if ($c->req->params->{submit}) {
		$c->form($ips_form_validate);
	
		unless ($c->form->has_missing || $c->form->has_invalid || $c->form->has_unknown) {
		
			# Remove ips/domains and recreate links, then update and save the site
			
            my $err_flag = 0;
			eval {
				CUFTS::DB::SiteDomains->search('site' => $c->stash->{current_site}->id)->delete_all;
				CUFTS::DB::SiteIPs->search('site' => $c->stash->{current_site}->id)->delete_all;

				foreach my $param (keys(%{$c->form->valid})) {
					my $value = $c->form->valid->{$param};
		
					if ($param =~ /^domain/) {
						$value =~ /^\./ or 
							$value = '.' . $value;
						$c->stash->{current_site}->add_to_domains({'domain' => $value});
					} elsif ($param =~ /^ip_low_(.+)/) {
					    my $low = $value;
					    my $high = $c->form->valid->{"ip_high_$1"};
					    
					    if ( is_empty_string($low) || is_empty_string($high) ) {
					        push @{$c->stash->{errors}}, "IP ranges must include high and low values.\n";
					        $err_flag = 1;
					        next;
					    }
					    
						$c->stash->{current_site}->add_to_ips( {'ip_low' => $low, 'ip_high' => $high} );
					}
				}
			};

            if ( !$err_flag ) {
    			if ($@) {
    				my $err = $@;
    				CUFTS::DB::DBI->dbi_rollback;
    				die($err);
    			}
			
    			CUFTS::DB::DBI->dbi_commit;
    			return $c->redirect('/site/edit');
    		}
    		else {
    		    CUFTS::DB::DBI->dbi_rollback;
    		}
		}
	}
	
	$c->stash->{section} = 'general';
	$c->stash->{template} = 'site/ips.tt';
}


=head1 NAME

CUFTS::MaintTool::C::Site - Component for sites

=head1 SYNOPSIS

Handles site editing, changing sites, etc.

=head1 DESCRIPTION

Handles site editing, changing sites, etc.

=head1 AUTHOR

Todd Holbrook

=head1 LICENSE

This library is free software . You can redistribute it and/or modify 
it under the same terms as perl itself.

=cut

1;

