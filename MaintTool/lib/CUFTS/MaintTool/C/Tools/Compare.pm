package CUFTS::MaintTool::C::Tools::Compare;

use strict;
use base 'Catalyst::Base';

use CUFTS::DB::Resources;
use CUFTS::DB::Journals;
use CUFTS::Util::Simple;

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

    my @globalresources = CUFTS::DB::Resources->search( { active => 'true' }, { order_by => 'name' } );
    my @localresources  = CUFTS::DB::LocalResources->search( { site => $c->stash->{current_site}->id, active => 'true' }, { order_by => 'name' } );

    @localresources = sort { ( $a->name || $a->resource->name ) cmp ( $b->name || $b->resource->name ) } @localresources;

    $c->stash->{localresources}  = \@localresources;
    $c->stash->{globalresources} = \@globalresources;
    $c->stash->{template}        = 'tools/compare/default.tt';
}

sub results : Local {
    my ( $self, $c, $journal_auth_id, $fulltext ) = @_;

    $c->form( $form_validate );

    my @resources;
    foreach my $param ( qw( compare1 compare2 compare3 compare4 ) ) {
        my $longid = $c->form->valid->{$param};
        next if is_empty_string($longid);
        my $type = substr($longid,0,1);
        my $id   = substr($longid,1);
        
        if ( $type eq 'l' ) {
            push @resources,
                CUFTS::DB::LocalResources->retrieve( $id );
        }
        else {
            push @resources,
                CUFTS::DB::Resources->retrieve( $id );
        }
    }

    my %data;
    my %titles;
    my @unmatched;

    foreach my $resource (@resources) {
        
        my $journal_iter;
        if ( $resource->can('resource') ) {
            $journal_iter = CUFTS::DB::LocalJournals->search( { resource => $resource->id, active => 'true' } );
        }
        else {
            $journal_iter = CUFTS::DB::Journals->search( { resource => $resource->id } );
        }

JOURNAL:
        while ( my $journal_rec = $journal_iter->next ) {

            my $journal = _overlay_journal( $journal_rec );

            if ( $c->form->valid->{fulltext} ) {
                if (    !defined($journal->{ft_start_date}  )
                     && !defined($journal->{ft_end_date}    )
                     && !defined($journal->{current_months} )
                     && !defined($journal->{current_years}  )
                     && !defined($journal->{embargo_days}   )
                     && !defined($journal->{embargo_months} ) ) {
                         next JOURNAL;
                 }
            }


            my $ja = $journal->{journal_auth};

            if ( defined($ja) ) {
                my $journal_auth_id = $journal->{journal_auth}->id;

                if ( !exists( $data{ $journal_auth_id } ) ) {

                    $data{ $journal_auth_id } = {
                        journal_auth => $ja,
                        resources => {},
                    };

                    $titles{ $journal_auth_id } = $ja->title;   

                }

                $data{ $journal_auth_id }->{ resources }->{ $resource->id } = $journal;

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
        $c->stash->{template}  = 'tools/compare/results.tt';
    }
    elsif ( $c->form->valid->{format} eq 'delimited' ) {
        $c->stash->{template}  = 'tools/compare/tab.tt';
    }
    else {
        die("Unrecognized format: " . $c->form->valid->{format} );
    }
}

sub _overlay_journal {
    my ( $journal ) = @_;
    
    my $global;
    if ( $journal->can('journal') ) {
        $global = $journal->journal;
    }

    my %data;
    
    foreach my $column (
        qw(title issn e_issn vol_cit_start vol_cit_end iss_cit_start iss_cit_end vol_ft_start vol_ft_end iss_ft_start iss_ft_end cit_start_date cit_end_date ft_start_date ft_end_date embargo_months embargo_days current_months current_years coverage journal_auth)
    ) {
            $data{$column} = $journal->$column() || ( defined($global) ? $global->$column() : undef );
    }

    return \%data;
}

1;
