package CUFTS::MaintTool::C::Public::Compare;

use strict;
use base 'Catalyst::Base';

use CUFTS::DB::Resources;
use CUFTS::DB::Journals;

my $form_validate = {
     required => [ 'format', 'compare', 'compare1', 'compare2', ],
     optional => [ 'compare3', 'compare4', 'fulltext', ],
};

sub auto : Private {
    my ( $self, $c ) = @_;

    $c->stash->{header_section} = 'Resource Comparison';
    push( @{ $c->stash->{load_css} }, 'public_tools.css' );
}

sub default : Private {
    my ( $self, $c ) = @_;

    my @resources = CUFTS::DB::Resources->search( { active => 'true' }, { order_by => 'name' } );

    $c->stash->{resources} = \@resources;
    $c->stash->{template}  = 'public/compare/default.tt';
}

sub results : Local {
    my ( $self, $c, $journal_auth_id, $fulltext ) = @_;

    $c->form( $form_validate );

    my @resources;
    push @resources,
        CUFTS::DB::Resources->retrieve( $c->form->valid->{compare1} );
    push @resources,
        CUFTS::DB::Resources->retrieve( $c->form->valid->{compare2} );
    if ( defined( $c->form->valid->{compare3} ) ) {
        push @resources,
            CUFTS::DB::Resources->retrieve( $c->form->valid->{compare3} );
    }
    if ( defined( $c->form->valid->{compare4} ) ) {
        push @resources,
            CUFTS::DB::Resources->retrieve( $c->form->valid->{compare4} );
    }

    my %data;
    my %titles;
    my @unmatched;

    foreach my $resource (@resources) {
        my $journal_iter = CUFTS::DB::Journals->search( { resource => $resource->id } );

JOURNAL:
        while ( my $journal = $journal_iter->next ) {

            if ( $c->form->valid->{fulltext} ) {
                if (    !defined($journal->ft_start_date  )
                     && !defined($journal->ft_end_date    )
                     && !defined($journal->current_months )
                     && !defined($journal->current_years  )
                     && !defined($journal->embargo_days   )
                     && !defined($journal->embargo_months ) ) {
                         next JOURNAL;
                 }
            }


            if ( defined( $journal->journal_auth ) ) {
                $journal_auth_id = $journal->journal_auth->id;

                if ( !exists( $data{ $journal_auth_id } ) ) {
                    $data{ $journal_auth_id } = {
                        journal_auth => $journal->journal_auth,
                        resources => {},
                    };
                }

                $data{ $journal_auth_id }->{ resources }->{ $resource->id } = $journal;

                if ( !exists( $titles{$journal_auth_id} ) ) {
                    $titles{ $journal_auth_id } = $journal->journal_auth->title;   
                }

            }
            else {
                push @unmatched, $journal;
            }
        }

    }

    my @order;
    foreach my $id ( keys %titles ) {
        push @order, [ lc($titles{$id}), $id ];
    }
    
    @order = sort { ${$a}[0] cmp ${$b}[0] } @order;

    $c->stash->{order}     = \@order;
    $c->stash->{data}      = \%data;
    $c->stash->{unmatched} = \@unmatched;
    $c->stash->{resources} = \@resources;
    if ( $c->form->valid->{format} eq 'html' ) {
        $c->stash->{template}  = 'public/compare/results.tt';
    }
    elsif ( $c->form->valid->{format} eq 'delimited' ) {
        $c->stash->{template}  = 'public/compare/tab.tt';
    }
    else {
        die("Unrecognized format: " . $c->form->valid->{format} );
    }
}

1;
