package CUFTS::MaintTool::C::Site::GoogleScholar;

use strict;
use base 'Catalyst::Base';

my $form_validate = {
	optional => [qw{
	    submit
	    cancel
        google_scholar_keywords
        google_scholar_e_link_label
        google_scholar_other_link_label
        google_scholar_openurl_base
        google_scholar_other_xml
	    
	}],
	required => [qw{
        google_scholar_on
	}],
	missing_optional_valid => 1,
	filters  => ['trim'],
};

sub edit : Local {
	my ($self, $c) = @_;

	$c->req->params->{cancel} and
		return $c->redirect('/site/edit');

	if ($c->req->params->{submit}) {
		$c->form($form_validate);
		
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

	$c->stash->{section} = 'googlescholar';
	$c->stash->{template} = 'site/googlescholar.tt';
}




=head1 NAME

CUFTS::MaintTool::C::Site::GoogleScholar - Component for GoogleScholar related data

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

