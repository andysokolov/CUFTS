package CUFTS::MaintTool::C::Site::CRDB;

use strict;
use base 'Catalyst::Base';

use CUFTS::DB::ERMDisplayFields;

use CUFTS::Util::Simple;

my $form_settings_validate = {
    optional_regexp => qr/^(show_field|staff_)/,
    required => [ 'submit' ],
};


sub settings : Local {
    my ( $self, $c ) = @_;

    $c->req->params->{cancel}
        and return $c->redirect('/site/edit');

    if ( $c->req->params->{submit} ) {
        $c->form($form_settings_validate);

        unless ( $c->form->has_missing || $c->form->has_invalid || $c->form->has_unknown ) {
            
            CUFTS::DB::ERMDisplayFields->search({ site => $c->stash->{current_site}->id } )->delete_all();

            # Loop through "show_field" params, since the staff ones should not appear
            # without a matching "show_field"

            my @records;
            foreach my $param ( keys %{ $c->form->valid } ) {
                next unless $param =~ /^show_field-(.+)$/;
                my $field = $1;
                my $order = $c->form->valid->{$param};
                my $staff_only = $c->form->valid->{'staff_only-' . $field} || 0;
                my $staff_edit = $c->form->valid->{'staff_edit-' . $field} || 0;

                CUFTS::DB::ERMDisplayFields->create({
                    field         => $field,
                    staff_view    => $staff_only,
                    staff_edit    => $staff_edit,
                    display_order => $order,
                    site          => $c->stash->{current_site}->id,
                });

            }

            CUFTS::DB::DBI->dbi_commit();
        }
    }

    my @active_ordered = CUFTS::DB::ERMDisplayFields->search( { site => $c->stash->{current_site}->id }, { order_by => 'display_order'} );
    my %active_fields  = map { $_->{field} => $_ } @active_ordered;

    $c->stash->{active_fields}  = \%active_fields;
    $c->stash->{active_ordered} = \@active_ordered;
    $c->stash->{all_fields}     = all_viewable_crdb_fields();
    $c->stash->{header_section} = 'Site Settings : CRDB Settings';
    $c->stash->{template}       = 'site/crdb/settings.tt';
}


sub all_viewable_crdb_fields {

    my @ignore_fields = qw(
        id
        key
        site
        license
        provider
        created
        modified
    );
    
    my %fields;
    
    foreach my $field ( CUFTS::DB::ERMMain->columns() ) {
        next if grep {$_ eq $field} @ignore_fields;
        $fields{ $field } = 1;
    }
    foreach my $field ( CUFTS::DB::ERMLicense->columns() ) {
        next if grep {$_ eq $field} @ignore_fields;
        $fields{ $field } ||= 0;
    }
    foreach my $field ( CUFTS::DB::ERMProviders->columns() ) {
        next if grep {$_ eq $field} @ignore_fields;
        $fields{ $field } ||= 0;
    }

    # Add relationship fields where useful (subjects, etc.)

    $fields{content_types} = 1;
    $fields{subjects} = 1;
    $fields{names} = 1;
    

    return \%fields;
}


=head1 NAME

CUFTS::MaintTool::C::Site::CRDB - Component for CRDB settings

=head1 SYNOPSIS

Handles site editing for CRDB specific options

=head1 DESCRIPTION

Handles site editing for CRDB specific options

=head1 AUTHOR

Todd Holbrook

=head1 LICENSE

This library is free software . You can redistribute it and/or modify 
it under the same terms as perl itself.

=cut

1;

