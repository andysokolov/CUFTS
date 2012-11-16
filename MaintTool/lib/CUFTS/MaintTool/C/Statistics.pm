package CUFTS::MaintTool::C::Statistics;

use strict;
use base 'Catalyst::Base';

sub menu : Local {
	my ($self, $c) = @_;
	
	# Check for cancel button

	$c->req->params->{cancel} and
		return $c->redirect('/main');

    $c->stash->{header_section} = 'Statistics';
    
	if ($c->req->params->{submit}) {

		$c->form({
		           optional => ['cancel', 'submit'], 
			   required => ['statistics_type', 'statistics_time'],
		         });

		($c->stash->{time} = $c->form->valid->{statistics_time}) =~ tr/_/ /;
		

		if ($c->form->valid->{statistics_type} =~ 'top50journals_(yes|no)_fulltext') {
			my $results = CUFTS::DB::Stats->top50journals($c->stash->{current_site}->id, $c->form->valid->{statistics_time}, $1 eq 'yes' ? 't' : 'f');
			$c->stash->{statistics} = $results;
			$c->stash->{fulltext} = $1;
			$c->stash->{template} = 'statistics/top50_journals.tt';
		} elsif ($c->form->valid->{statistics_type} eq 'request_count')  {
			my $results = CUFTS::DB::Stats->requests_count($c->stash->{current_site}->id, $c->form->valid->{statistics_time});
			$c->stash->{statistics} = $results;
			$c->stash->{template} = 'statistics/request_count.tt';
		} else {
			die('Unrecognized statistics type selected: ' . $c->form->valid->{statistics_type});
		}
	} else {
		$c->stash->{template} = 'statistics/menu.tt';
	}
}


1;

