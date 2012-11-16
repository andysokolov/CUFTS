package CUFTS::MaintTool::C::Admin::Account;

use strict;
use base 'Catalyst::Base';

my $form_validate_edit = {
	required => ['name', 'key'],
	optional => ['email', 'phone', 'active', 'edit_global', 'journal_auth', 'administrator', 'account_sites', 'submit', 'cancel' ],
	defaults => { 
		'active' => 'false', 
		'edit_global' => 'false',
		'administrator' => 'false',
		'journal_auth' => 'false',
		'account_sites' => []
	},
	filters => ['trim'],
	dependency_groups => {
		password => ['password', 'verify_password']
	},
	constraints => {
		password => {
			constraint => sub { $_[0] eq $_[1] },
			params => ['password', 'verify_password'],
		},
	},
	missing_optional_valid => 1,
};

my $form_validate_new = { %$form_validate_edit };
$form_validate_new->{required} = ['name', 'key', 'password'];



sub auto : Private {
	my ($self, $c, $account_id) = @_;

	if ($account_id != 0) {
		$c->stash->{account} = CUFTS::DB::Accounts->retrieve($account_id);
		defined($c->stash->{account}) or
			die("Unable to load account: $account_id");
	}

    $c->stash->{header_section} = 'Account Administration';

	return 1;
}

sub menu : Local {
	my ($self, $c) = @_;

	my @accounts = CUFTS::DB::Accounts->retrieve_all();
	$c->stash->{accounts} = \@accounts;
	$c->stash->{template} = 'admin/account/menu.tt';
}

sub view : Local {
	my ($self, $c, $account_id) = @_;

	defined($c->stash->{account}) or
		return die('No account loaded to view');

	$c->stash->{template} = 'admin/account/view.tt';
}	


sub edit : Local {
	my ($self, $c, $account_id) = @_;

	$c->req->params->{cancel} and
		return $c->redirect('/admin/account/menu');

	my $account = $c->stash->{account};

	if ($c->req->params->{submit}) {
		
		$c->form(defined($account) ? $form_validate_edit : $form_validate_new);

		defined($c->form->{valid}->{password}) and
			$c->form->{valid}->{password} = crypt $c->form->{valid}->{password}, $c->form->{valid}->{key};

		unless ($c->form->has_missing || $c->form->has_invalid || $c->form->has_unknown) {
		
			# Remove accounts and recreate links, then update and save the account
			
			eval {
				if (defined($account)) {
					$account->update_from_form($c->form);
					CUFTS::DB::Accounts_Sites->search(account => $account_id)->delete_all;
				} else {
					$account = CUFTS::DB::Accounts->create_from_form($c->form);
				}
				
				foreach my $site ($c->form->valid('account_sites')) {
					$account->add_to_sites({ site => $site });
				}
			};
			if ($@) {
				CUFTS::DB::DBI->dbi_rollback;
				die;
			}
			
			CUFTS::DB::DBI->dbi_commit;
			return $c->redirect('/admin/account/menu');
		}
	}

	$c->stash->{account} = $account;
	$c->stash->{sites} = [CUFTS::DB::Sites->retrieve_all()];
	$c->stash->{template} = 'admin/account/edit.tt';
}
		
sub delete : Local {
	my ($self, $c, $account_id) = @_;
	
	defined($c->stash->{account}) or
		 die('No account loaded to delete.');
		
	$c->stash->{account}->delete();
	CUFTS::DB::DBI->dbi_commit;
	
	$c->redirect('/admin/account/menu');
}

1;