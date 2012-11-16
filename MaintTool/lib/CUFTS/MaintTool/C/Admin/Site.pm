package CUFTS::MaintTool::C::Admin::Site;

use strict;
use base 'Catalyst::Base';

my $form_validate = {
	required => ['name', 'key'],
	optional => ['proxy_prefix', 'proxy_prefix_alternate', 'email', 'erm_notification_email', 'active', 'site_accounts', 'submit', 'cancel'],
	defaults => { 'active' => 'false', 'site_accounts' => [] },
	filters => ['trim'],
	missing_optional_valid => 1,
};


sub auto : Private {
	my ($self, $c, $site_id) = @_;

	if ($site_id != 0) {
		$c->stash->{site} = CUFTS::DB::Sites->retrieve($site_id);
		defined($c->stash->{site}) or
			die("Unable to load site: $site_id");
	}

    $c->stash->{header_section} = 'Site Administration';

	return 1;
}

sub menu : Local {
	my ($self, $c) = @_;

	my @sites = CUFTS::DB::Sites->retrieve_all();
	$c->stash->{sites} = \@sites;
	$c->stash->{template} = 'admin/site/menu.tt';
}

sub view : Local {
	my ($self, $c, $site_id) = @_;

	defined($c->stash->{site}) or
		return die('No site loaded to view');

	$c->stash->{template} = 'admin/site/view.tt';
}	


sub edit : Local {
	my ($self, $c, $site_id) = @_;

	$c->req->params->{cancel} and
		return $c->redirect('/admin/site/menu');

	my $site = $c->stash->{site};

	if ($c->req->params->{submit}) {
		
		$c->form($form_validate);
		unless ($c->form->has_missing || $c->form->has_invalid || $c->form->has_unknown) {
		
			# Remove sites and recreate links, then update and save the site
			
			eval {
				if (defined($site)) {
					$site->update_from_form($c->form);
					CUFTS::DB::Accounts_Sites->search(site => $site_id)->delete_all;
				} else {
					$site = CUFTS::DB::Sites->create_from_form($c->form);
				}
				
				foreach my $account ($c->form->valid('site_accounts')) {
					$site->add_to_accounts({ account => $account });
				}
			};
			if ($@) {
				CUFTS::DB::DBI->dbi_rollback;
				die;
			}
			
			CUFTS::DB::DBI->dbi_commit;
			return $c->redirect('/admin/site/menu');
		}
	}

	$c->stash->{site} = $site;
	$c->stash->{accounts} = [CUFTS::DB::Accounts->retrieve_all()];
	$c->stash->{template} = 'admin/site/edit.tt';
}
		
sub delete : Local {
	my ($self, $c, $site_id) = @_;
	
	defined($c->stash->{site}) or
		 die('No site loaded to delete.');
		
	$c->stash->{site}->delete();
	CUFTS::DB::DBI->dbi_commit;
	
	$c->redirect('/admin/site/menu');
}

1;