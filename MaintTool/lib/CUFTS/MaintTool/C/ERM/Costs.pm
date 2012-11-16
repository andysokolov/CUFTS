package CUFTS::MaintTool::C::ERM::Costs;

use strict;
use base 'Catalyst::Base';

use CUFTS::DB::ERMCosts;
use CUFTS::Util::Simple;

my $view_form_validate = {
    optional => [ qw( new_id ) ],
};

my $main_form_validate = {
    optional => [ qw( add save invoice invoice_currency paid paid_currency order_number number reference ) ],
    required => [ qw( date period_start period_end ) ],
    filters => ['trim'],
    constraints => {
        date         => qr/^\d{4}-\d{1,2}-\d{1,2}/,
        period_start => qr/^\d{4}-\d{1,2}-\d{1,2}/,
        period_end   => qr/^\d{4}-\d{1,2}-\d{1,2}/,
        invoice      => qr/^-?\d{0,8}\.?\d{0,2}$/,
        paid         => qr/^-?\d{0,8}\.?\d{0,2}$/,
    },
    js_constraints => {
        date          => { dateISO => 'true' },
        period_start  => { dateISO => 'true' },
        period_end    => { dateISO => 'true' },
    },
};



sub auto : Private {
    my ( $self, $c ) = @_;
}

sub view : Local {
    my ( $self, $c, $erm_main_id ) = @_;

    # Don't revalidate the form in case we were forwarded here from /add

    if ( $c->form->has_unknown('new_id') ) {
        $c->form( $view_form_validate );
        $c->stash->{new_id} = $c->form->valid('new_id');
    }
    
    # Verify the ERM Costs data requested belongs to the current site.
    
    my $erm = CUFTS::DB::ERMMain->search({ id => $erm_main_id, site => $c->stash->{current_site}->id })->first;
    if ( !defined($erm) ) {
        die("Unable to find ERM record: $erm_main_id for current site.");
    }

    # Get costs
    
    my @costs = $erm->costs();

    $c->stash->{costs} = [ sort { $b->date cmp $a->date } @costs ];
    $c->stash->{erm} = $erm;
    $c->stash->{template} = 'erm/costs/view.tt';
}

sub add : Local {
    my ( $self, $c, $erm_main_id ) = @_;

    $c->form( $main_form_validate );

    if ( $c->form->has_missing || $c->form->has_invalid || $c->form->has_unknown ) {
        return $c->forward("view/$erm_main_id");
    }
    
    # Verify the ERM Costs data requested belongs to the current site.
    
    my $erm = CUFTS::DB::ERMMain->search({ id => $erm_main_id, site => $c->stash->{current_site}->id })->first;
    if ( !defined($erm) ) {
        die("Unable to find ERM record: $erm_main_id for current site.");
    }

    # Create cost record from form

    $c->form->valid('erm_main', $erm->id);
    my $new_erm = CUFTS::DB::ERMCosts->create_from_form($c->form);
    CUFTS::DB::ERMCosts->dbi_commit();
    
    return $c->redirect("/erm/costs/view/$erm_main_id?new_id=" . $new_erm->id );
}

sub delete : Local {
    my ( $self, $c ) = @_;
    
    my $cost = CUFTS::DB::ERMCosts->search( { id => $c->req->params->{cost_id} } )->first;
    if ( !defined($cost) ) {
        die("Unable to find cost id: " . $c->req->params->{cost_id});
    }
    
    my $erm = $cost->erm_main;
 
    # Verify the ERM Costs data requested belongs to the current site.

    if ( $erm->site != $c->stash->{current_site}->id ) {
        die("Attempt to delete a cost for a site other than the current one.")
    }
    
    $cost->delete();
    CUFTS::DB::DBI->dbi_commit();
    
    return $c->redirect("/erm/costs/view/" . $erm->id);
}

sub edit : Local {
    my ( $self, $c, $cost_id ) = @_;

    my $cost = CUFTS::DB::ERMCosts->search( { id => $cost_id } )->first;
    if ( !defined($cost) ) {
        die("Unable to find cost id: " . $c->req->params->{cost_id});
    }
    
    my $erm = $cost->erm_main;
 
    # Verify the ERM Costs data requested belongs to the current site.

    if ( $erm->site != $c->stash->{current_site}->id ) {
        die("Attempt to edit a cost for a site other than the current one.")
    }

    if ( $c->req->params->{save} ) {
        $c->form( $main_form_validate );

        unless ( $c->form->has_missing || $c->form->has_invalid || $c->form->has_unknown ) {

            $cost->update_from_form( $c->form );
            CUFTS::DB::DBI->dbi_commit();
            return $c->redirect("/erm/costs/view/" . $erm->id);
        }
    }

    $c->stash->{erm} = $cost->erm_main;
    $c->stash->{cost} = $cost;
    $c->stash->{template} = 'erm/costs/edit.tt';
}



=head1 NAME

CUFTS::MaintTool::C::ERM::Tables - Component for ERM related data

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

