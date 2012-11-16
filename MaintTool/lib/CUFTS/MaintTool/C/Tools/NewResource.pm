package CUFTS::MaintTool::C::Tools::NewResource;

use strict;
use base 'Catalyst::Base';

use CUFTS::DB::Resources;
use CUFTS::DB::Journals;
use CUFTS::DB::MergedJournals;
use CUFTS::Util::Simple;

my $form_validate = {
     required => [ 'format', 'compare', 'compare1' ],
     optional => [ 'fulltext' ],
};

sub auto : Private {
    my ( $self, $c ) = @_;

    $c->stash->{header_section} = 'New Resource Comparison';
    push( @{ $c->stash->{load_css} }, 'public_tools.css' );
}

sub default : Private {
    my ( $self, $c ) = @_;

    my @localresources  = CUFTS::DB::LocalResources->search( { site => $c->stash->{current_site}->id, active => 'true' } );
    my %local_resource_ids = ( map { $_->resource => 1 } @localresources );

    my @globalresources = grep { !$local_resource_ids{$_->id} } CUFTS::DB::Resources->search( { active => 'true' }, { order_by => 'name' } );

    $c->stash->{globalresources} = \@globalresources;
    $c->stash->{template}        = 'tools/newresource/default.tt';
}

sub results : Local {
    my ( $self, $c, $journal_auth_id, $fulltext ) = @_;

    my $site_id = $c->stash->{current_site}->id;

    $c->form( $form_validate );

    my $resource_id = $c->form->valid->{compare1};
    my $resource = CUFTS::DB::Resources->retrieve( $resource_id );

    my @unique;
    my @dupes;

    my $journal_iter = CUFTS::DB::Journals->search( { resource => $resource_id }, { order_by => 'title' } );

JOURNAL:
    while ( my $journal = $journal_iter->next ) {
        next if !$journal->journal_auth;

        # Find other journals...

        my @other_journals = CUFTS::DB::JournalsActive->search({
            journal_auth            => $journal->journal_auth->id,
            resource                => { '!=' => $resource_id },
            'local_resource.site'   => $site_id,
            'local_resource.active' => 't',
        });

        push @other_journals, CUFTS::DB::LocalJournals->search({
            journal_auth                => $journal->journal_auth->id,
            journal                     => undef,
            'resource.resource'         => undef,
            'resource.site'             => $site_id,
            'resource.active'           => 't',
            active                      => 't',
        });

        if ( !scalar(@other_journals) ) {
            push @unique, $journal;
        }
        else {
            push @dupes, [ $journal, _analyze_coverage($journal, \@other_journals), \@other_journals ];
        }

    }

    $c->stash->{unique}     = \@unique;
    $c->stash->{dupes}      = \@dupes;
    $c->stash->{resource}   = $resource;

    if ( $c->form->valid->{format} eq 'html' ) {
        $c->stash->{template}  = 'tools/newresource/results.tt';
    }
    elsif ( $c->form->valid->{format} eq 'delimited' ) {
        $c->stash->{template}  = 'tools/newresource/tab.tt';
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

# Looks at the coverage to see if it's "better".  Returns a class name that can be used to highlight rows
# in the results.

sub _analyze_coverage {
    my ( $journal, $others ) = @_;
    
    # Journal has no fulltext, don't bother comparing it against other records
    return 'no_ft' if !grep { $journal->{$_} } qw( ft_start_date ft_end_date embargo_days embargo_months current_months current_years );

    # Journal has embargo/current coverage which is difficult to compare, so for now we'll just call it "unknown"
    return 'unknown' if grep { $journal->{$_} } qw( embargo_days embargo_months current_months current_years );

    my $start_date = '';
    my $end_date = '';

    foreach my $other ( @$others ) {
        my $other_journal_data = _overlay_journal($other);

        return 'unknown' if grep { $other_journal_data->{$_} } qw( embargo_days embargo_months current_months current_years );

        if ( $other_journal_data->{ft_start_date} && ( !$start_date || $other_journal_data->{ft_start_date} lt $start_date ) ) {
            $start_date = $other_journal_data->{ft_start_date};
        }

        if ( $other_journal_data->{ft_end_date} && ( !$end_date || $other_journal_data->{ft_end_date} gt $end_date ) ) {
            $end_date = $other_journal_data->{ft_end_date};
        }
    }

    if ( $journal->ft_start_date eq $start_date && $journal->ft_end_date eq $end_date ) {
        return 'equal';
    }

    if (    $journal->ft_start_date lt $start_date
         || $journal->ft_end_date   gt $end_date
         || ( !$journal->ft_end_date && $end_date ) ) {
        return 'more';
    }

    return 'less';

}

1;
