package CUFTS::MaintTool4::Controller::Site;
use Moose;
use namespace::autoclean;

use String::Util qw(hascontent trim);
use Data::FormValidator::Constraints qw(ip_address);

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

CUFTS::MaintTool4::Controller::Site - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub base :Chained('/loggedin') :PathPart('site') :CaptureArgs(0) {}

sub change :Chained('base') :PathPart('change') :Args(0) {
    my ( $self, $c ) = @_;

    $c->form({ optional => ['new_site', 'submit'] });

    # Build list of sites used for both display and confirmation of
    # access to chosen site

    my $site_rs   = $c->user->administrator ? $c->model('CUFTS::Sites') : $c->user->sites;
    my @site_list = $site_rs->search({}, { order_by => 'name' } );

    my $new_site_id = int( $c->form->valid->{new_site} || 0);
    if ( $new_site_id ) {

        # Change the site if this is a submission.  Check to make sure the user
        # isn't trying to switch to a site they don't have access to

        my @check_list = grep { $_->id == $new_site_id } @site_list;
        if (scalar(@check_list) == 1) {
            $c->site($check_list[0]);
            $c->session->{current_site_id} = $check_list[0]->id;
            return $c->redirect( $c->uri_for( $c->controller('Root')->action_for('index') ) );
        }
        else {
            $c->stash_errors( $c->loc('You do not have permission to change to that site.') );
        }

    }

    # Display a list of sites

    $c->stash->{sites} = \@site_list;
    $c->stash->{template} = 'site/change.tt';
}


sub edit :Chained('base') :PathPart('edit') :Args(0) {
    my ($self, $c) = @_;

    my $form_validate = {
        required => [ qw( name email ) ],
        optional => [ qw( erm_notification_email proxy_prefix proxy_prefix_alternate proxy_WAM show_ERM submit ) ],
        filters  => [ qw( trim ) ],
        missing_optional_valid => 1,
    };

    if ( $c->has_param('submit') ) {

        $c->stash_params();
        $c->form($form_validate);

        unless ( $c->form_has_errors ) {

            eval {
                $c->site->update_from_fv($c->form);
            };
            if ($@) {
                $c->stash_errors($@);
            }
            else {
                $c->stash_results( $c->loc('Site data updated.') );
            }

        }

    }

    $c->stash->{site}       = $c->site;
    $c->stash->{template}   = 'site/edit.tt';
}


sub ips :Chained('base') :PathPart('ips') :Args(0)  {
    my ( $self, $c ) = @_;

    my $form_validate = {
        optional => [ 'submit' ],
        optional_regexp => qr/^(ip|domain)/,
        filters => ['trim'],
        constraint_method_regexp_map => {
          qr/^ip_low/   => ip_address(),
          qr/^ip_high/  => ip_address(),
        },
        constraint_regexp_map => {
          qr/^domain/ => qr/^[-\w\.]+$/,  # /
        },
    };
    $c->stash->{field_messages} = {
        generic => {
            ip => $c->loc('Must be in 1.2.3.4 format.'),
        }
    };

    if ( $c->has_param('submit') ) {

        $c->form($form_validate);
        $c->stash_params();
        my $params = $c->request->params;

        $c->stash->{domains} = [ map { { name => $_, domain => $params->{$_} } } sort grep {/^domain/} keys %{$params} ];

        my @ips;
        foreach my $param ( keys %{$params} ) {
            next unless $param =~ /ip_high(\d+)/;
            push @ips, { name => $1, ip_high => $params->{$param}, ip_low => $params->{"ip_low$1"} };
        }
        $c->stash->{ips} = \@ips;

        unless ( $c->form_has_errors ) {

            # Remove ips/domains and recreate links, then update and save the site

            my $err_flag = 0;
            eval {
                $c->model('CUFTS')->txn_do( sub {

                    $c->site->domains->delete_all();
                    $c->site->ips->delete_all();

                    foreach my $param ( keys %{$c->form->valid} ) {

                        my $value = $c->form->valid->{$param};
                        next if !hascontent($value);

                        if ( $param =~ /^domain/ ) {
                            # Domains should start with a "."
                            $value =~ /^\./ or
                                $value = '.' . $value;

                            $c->site->add_to_domains({ domain  => $value });

                        } elsif ( $param =~ /^ip_low(.+)/ ) {

                            my $low = $value;
                            my $high = $c->form->valid->{"ip_high$1"};

                            if ( !hascontent($low) || !hascontent($high) ) {
                                push @{$c->stash->{errors}}, $c->loc('IP ranges must include high and low values.');
                                $err_flag = 1;
                                next;
                            }

                            $c->site->add_to_ips({ ip_low => $low, ip_high => $high });
                        }

                    }
                });
            };

            if ( !$err_flag ) {
                if ($@) {
                    $c->stash_errors($@);
                }
                else {
                    $c->flash_results( $c->loc('Site data updated.') );
                    return $c->redirect( $c->uri_for( $c->controller('Site')->action_for('ips') ) );
                }
            }
        }
    }

    $c->stash->{domains}  = [ $c->site->domains({}, { order_by => 'domain' }) ];
    $c->stash->{ips}      = [ $c->site->ips({},     { order_by => 'ip_low' }) ];

    $c->stash->{template} = 'site/ips.tt';
}



sub google_scholar :Chained('base') :PathPart('google_scholar') Args(0) {
    my ($self, $c) = @_;


    my $form_validate = {
        optional => [qw{
            submit
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

    if ( $c->has_param('submit') ) {
        $c->form($form_validate);

        unless ( $c->form_has_errors ) {

            eval {
                $c->site->update_from_fv($c->form);
            };
            if ($@) {
                $c->stash_errors($@);
            }
            else {
                $c->stash_results( $c->loc('Site data updated.') );
            }
        }
    }

    $c->stash->{template} = 'site/google_scholar.tt';
}





=head1 AUTHOR

tholbroo

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
