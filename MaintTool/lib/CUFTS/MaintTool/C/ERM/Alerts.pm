package CUFTS::MaintTool::C::ERM::Alerts;

use strict;
use base 'Catalyst::Base';

use JSON::XS qw( encode_json );

use CUFTS::Util::Simple;

use CUFTS::DB::ERMMain;
use List::MoreUtils;


sub auto : Private {
    my ( $self, $c ) = @_;

    return 1;
}


sub default : Private {
    my ( $self, $c ) = @_;

    my @resources = CUFTS::DB::ERMMain->search(
        {
            alert => { '!=' => undef },
            site => $c->stash->{current_site}->id,
        },
        {
            sql_method => 'with_name',
            order_by => 'result_name'
        }
    );

    
    $c->stash->{resources} = \@resources;
    $c->stash->{template} = "erm/alerts/alerts.tt";
}

sub delete : Local {
    my ( $self, $c ) = @_;

    $c->form({
        required => 'delete',
        optional => 'delete_ids',
    });
    
    if ( $c->form->valid->{delete} ) {
        my $ids = $c->form->{valid}->{delete_ids};
        if ( ref($ids) ne 'ARRAY' ) {
            $ids = [$ids];
        }
        
        foreach my $id ( @$ids ) {
            my $resource = CUFTS::DB::ERMMain->search({
                id => $id,
                site => $c->stash->{current_site}->id,
            })->first;
            if ( defined($resource) ) {
                $resource->alert(undef);
                $resource->alert_expiry(undef);
                $resource->update();
            }
        }
        CUFTS::DB::DBI->dbi_commit();
    }
    
    $c->redirect('/erm/alerts/');
}

sub alert_selected : Local {
    my ( $self, $c ) = @_;
    
    my @resources;
    if ( $c->session->{selected_erm_main} && scalar( @{$c->session->{selected_erm_main}} ) ) {
        @resources = CUFTS::DB::ERMMain->search(
            {
                id => { '-in' => $c->session->{selected_erm_main} },
                site => $c->stash->{current_site}->id,
            },
            {
                sql_method => 'with_name',
                order_by => 'result_name'
            }
        );
    }    

    $c->form({
        optional => [ qw( expiry ) ],
        required => [ qw( save message ) ],
        filters  => ['trim'],
        constraints => {
            expiry  => qr/^\d{4}-\d{1,2}-\d{1,2}/,
        },
    });

    unless ( $c->form->has_missing || $c->form->has_invalid || $c->form->has_unknown ) {
        my $date = $c->form->{valid}->{expiry};
        
        foreach my $resource ( @resources ) {
            $resource->alert( $c->form->{valid}->{message} );
            if ( $date ) {
                $resource->alert_expiry( $date );
            }
            $resource->update();
        }

        CUFTS::DB::DBI->dbi_commit();

    }
    
    $c->stash->{resources} = \@resources;
    $c->stash->{template}  = "erm/alerts/alert_selected.tt";
}

1;
