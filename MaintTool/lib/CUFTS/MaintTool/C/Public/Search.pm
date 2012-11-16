package CUFTS::MaintTool::C::Public::Search;

use strict;
use base 'Catalyst::Base';

use CUFTS::DB::JournalsAuth;
use CUFTS::DB::JournalsAuthTitles;
use CUFTS::DB::JournalsAuthISSNs;


my $form_validate = {
    required => [ 'search_field', 'search_text' ],
    optional => [ 'fulltext', 'search' ],
    filters => ['trim'],
};  

sub auto : Private {
    my ( $self, $c ) = @_;

    push( @{ $c->stash->{load_css} }, 'public_tools.css' );
    $c->stash->{header_section} = 'Journal Search';
}

sub default : Private {
    my ( $self, $c ) = @_;

    if ( $c->req->params->{search_text} ) {

        $c->form($form_validate);

        unless ($c->form->has_missing || $c->form->has_invalid || $c->form->has_unknown) {

            my @journal_auths;
            if ( $c->form->valid->{search_field} eq 'issn' ) {
                @journal_auths = CUFTS::DB::JournalsAuth->search_by_issns( $c->form->valid->{search_text} );
            }
            elsif ( $c->form->valid->{search_field} eq 'title' ) {
                    @journal_auths = CUFTS::DB::JournalsAuth->search_by_title( $c->form->valid->{search_text} . '%' );
            }

            my $fulltext = '';
            if ( $c->form->valid->{fulltext} ) {
                @journal_auths = grep { $_->has_fulltext } @journal_auths;   
                $fulltext = 'fulltext';
            }

            if ( scalar(@journal_auths) == 1 ) {
               return $c->forward('/public/search/journal', [ $journal_auths[0]->id, $fulltext ] );
            }

            @journal_auths = sort { lc($a->title) cmp lc($b->title) } @journal_auths;
            
            $c->stash->{journal_auths} = \@journal_auths;
            $c->stash->{fulltext} = $fulltext;
            $c->stash->{error} = 'autofillin';
        }

    }

    $c->stash->{template} = 'public/search/default.tt';
}


sub journal : Local {
    my ( $self, $c, $journal_auth_id, $fulltext ) = @_;

    my @holdings;
    my $journal_auth = CUFTS::DB::JournalsAuth->retrieve($journal_auth_id);
    
    my $search = { 'journal_auth' => $journal_auth->id };
    
    if ( $fulltext eq 'fulltext' ) {
        $search->{'-nest'} = [ map { $_, {'!=', undef} } @CUFTS::Config::CUFTS_JOURNAL_FT_FIELDS ];
    }
    
    my @journals = CUFTS::DB::Journals->search( $search );
    
    @journals = sort { $a->resource->provider cmp $b->resource->provider or $a->resource->name cmp $b->resource->name } @journals;
    push @holdings, \@journals;

    $c->stash->{journal_auth}  = $journal_auth;
    $c->stash->{holdings}      = \@holdings;
    $c->stash->{template}      = 'public/search/journal.tt';

}

1;