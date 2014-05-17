package CUFTS::MaintTool4::Controller::Site::Templates;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

CUFTS::MaintTool4::Controller::Site::Templates - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

my @valid_states   = qw( active sandbox );
my @valid_sections = qw( crdb4 cjdb4 );
my @valid_types    = qw( css template );

my $section_text = {
    cjdb4 => 'CJDB',
    crdb4 => 'CRDB',
};

my $template_lists = {
    cjdb4 => {
        templates => [ qw(
            account_bar.tt
            account_create.tt
            account_manage.tt
            account_tags.tt
            account_tags_view_string.tt
            azmenu.tt
            breadcrumbs.tt
            browse.tt
            browse_associations.tt
            browse_form.tt
            browse_journals.tt
            browse_journals_links.tt
            browse_subjects.tt
            coverage_strings.tt
            errors.tt
            journal.tt
            journal_account_tags.tt
            journal_associations.tt
            journal_coverages.tt
            journal_cover.tt
            journal_issns.tt
            journal_license.tt
            journal_links.tt
            journal_relations.tt
            journal_subjects.tt
            journal_tags.tt
            journal_titles.tt
            journals_link_name.tt
            layout.tt
            lcc_browse.tt
            list_sites.tt
            login.tt
            nav_line.tt
            page_footer.tt
            page_header.tt
            page_title.tt
            pager.tt
            results.tt
            selected_journals.tt
            selected_journals_data.tt
            setup_license_fields.tt
            site_setup.tt
        ) ],
        css => [ qw( cjdb.css ) ],
    },
    crdb4 => {
        templates => [ qw(
            account_bar.tt
            account_create.tt
            account_manage.tt
            breadcrumbs.tt
            browse.tt
            current_facets.tt
            display_field.tt
            display_record.tt
            errors.tt
            facet_labels.tt
            facet_menu.tt
            group_record_field.tt
            layout.tt
            list_sites.tt
            login.tt
            main.tt
            nav_line.tt
            not_allowed.tt
            page_footer.tt
            page_header.tt
            page_title.tt
            resource.tt
            results.tt
            site_setup.tt
        ) ],
        css => [ qw( crdb.css ) ],
    }

};

my $form_validate = {
    optional => [ 'submit', 'template_contents' ],
    filters  => [ 'trim' ],
};

sub base :Chained('/loggedin') :PathPart('site/templates') :CaptureArgs(0) {}

sub menu :Chained('base') :PathPart('menu') :Args(1) {
    my ( $self, $c, $section ) = @_;

    grep { $section eq $_ } @valid_sections
        or die("Invalid template section: $section");

    my $site = $c->site;

    my $active_dir  = get_site_base_dir($section, 'template', $site, '/active');
    my $sandbox_dir = get_site_base_dir($section, 'template', $site, '/sandbox');

    opendir ACTIVE, $active_dir
        or die('Unable to open site active template directory for reading');
    my @active_templates = grep !/^\./, readdir ACTIVE;
    closedir ACTIVE;

    opendir SANDBOX, $sandbox_dir
        or die('Unable to open  site sandbox template directory for reading');
    my @sandbox_templates = grep !/^\./, readdir SANDBOX;
    closedir SANDBOX;

    ##
    ## Get CSS files, active and sandbox lists
    ##

    my $active_css_dir  = get_site_base_dir( $section, 'css', $site, 'active'  );
    my $sandbox_css_dir = get_site_base_dir( $section, 'css', $site, 'sandbox' );

    opendir ACTIVE, $active_css_dir
        or die('Unable to open CJDB4 site active CSS directory for reading');
    my @active_css = grep !/^\./, readdir ACTIVE;
    closedir ACTIVE;

    opendir SANDBOX, $sandbox_css_dir
        or die('Unable to open CJDB4 site sandbox CSS directory for reading');
    my @sandbox_css = grep !/^\./, readdir SANDBOX;
    closedir SANDBOX;

    $c->stash->{active_templates}   = \@active_templates;
    $c->stash->{sandbox_templates}  = \@sandbox_templates;
    $c->stash->{templates}          = $template_lists->{$section}->{templates};

    $c->stash->{active_csses}  = \@active_css;
    $c->stash->{sandbox_csses} = \@sandbox_css;
    $c->stash->{csses}         = $template_lists->{$section}->{css};

    $c->stash->{active_url}  = get_site_url( $section, $site, 'active' );
    $c->stash->{sandbox_url} = get_site_url( $section, $site, 'sandbox' );

    $c->stash->{section}      = $section;
    $c->stash->{section_text} = $section_text->{$section};
    $c->stash->{template}     = 'site/templates/menu.tt';
}

sub view :Chained('base') :PathPart('view') :Args(4) {
    my ( $self, $c, $section, $type, $template_name, $state ) = @_;
    $c->stash->{template}      = 'site/templates/view.tt';
    $c->stash->{section}       = $section;
    $c->stash->{section_text}  = $section_text->{$section};
    $c->stash->{type}          = $type;
    $c->stash->{state}         = $state;
    $c->stash->{template_name} = $template_name;
    $c->forward( $c->controller->action_for('handle') );
}

sub edit :Chained('base') :PathPart('edit') :Args(3) {
    my ( $self, $c, $section, $type, $template_name ) = @_;
    $c->stash->{template}      = 'site/templates/edit.tt';
    $c->stash->{section}       = $section;
    $c->stash->{section_text}  = $section_text->{$section};
    $c->stash->{type}          = $type;
    $c->stash->{state}         = 'sandbox';
    $c->stash->{template_name} = $template_name;
    $c->forward( $c->controller->action_for('handle') );
}

sub handle :Private {
    my ( $self, $c ) = @_;

    my $state         = $c->stash->{state};
    my $section       = $c->stash->{section};
    my $type          = $c->stash->{type};
    my $template_name = $c->stash->{template_name};

    grep { $state eq $_ } @valid_states
        or die("Invalid template state: $state");

    grep { $section eq $_ } @valid_sections
        or die("Invalid template section: $section");

    grep { $type eq $_ } @valid_types
        or die("Invalid template type: $type");

    $template_name =~ /[\/\\;:'"]/   # Fix this, make it only tax a-z_. - Todd, 2009-04-27
        and die("Bad characters in template name: $template_name");

    my $base_dir = get_base_dir($section, $type);
    my $site_dir = get_site_base_dir($section, $type, $c->site, $state);

    my $template_contents;
    my $template_file =
        -e "${site_dir}/${template_name}"
        ?  "${site_dir}/${template_name}"
        :  "${base_dir}/${template_name}";

    open TEMPLATE, "${template_file}"
        or CUFTS::Exception::App::CGI->throw(qq{Unable to open template file "${template_file}": $!});
    while (<TEMPLATE>) {
        $template_contents .= $_;
    }
    close TEMPLATE;

    $c->stash->{template_name}     = $template_name;
    $c->stash->{template_contents} = $template_contents;
}

sub save :Chained('base') :PathPart('save') :Args(3) {
    my ( $self, $c, $section, $type, $template_name ) = @_;

    grep { $section eq $_ } @valid_sections
        or die("Invalid template section: $section");

    grep { $type eq $_ } @valid_types
        or die("Invalid template type: $type");

    $template_name =~ /[\/\\;:'"]/
        and die("Bad characters in template name: $template_name");

    $c->form($form_validate);
    if ( $c->form->has_missing || $c->form->has_invalid || $c->form->has_unknown ) {
        die('Error with edit form');
    }

    my $site_dir = get_site_base_dir( $section, $type, $c->site, 'sandbox' );

    open TEMPLATE, ">${site_dir}/${template_name}"
        or die("Unable to open template file: $!");
    print TEMPLATE $c->form->valid->{template_contents};
    close TEMPLATE;

    $c->flash->{results} = [ $c->loc('Saved template: ') . $template_name ];

    $c->redirect( $c->uri_for( $c->controller->action_for("menu"), [ $section ] ) );
}

sub delete :Chained('base') :PathPart('delete') :Args(4) {
    my ( $self, $c, $section, $type, $template_name, $state ) = @_;

    grep { $section eq $_ } @valid_sections
        or die("Invalid template section: $section");

    grep { $state eq $_ } @valid_states
        or die("Invalid template state: $state");

    grep { $type eq $_ } @valid_types
        or die("Invalid template type: $type");

    $template_name =~ /[\/\\;:'"]/
        and die("Bad characters in template name: $template_name");

    my $site_dir = get_site_base_dir( $section, $type, $c->site, $state );

    -e "${site_dir}/${template_name}"
            and unlink "${site_dir}/${template_name}"
                or die("Unable to unlink template file '${site_dir}/${template_name}': $!");

    $c->flash->{results} = [ $c->loc('Deleted template: ') . $template_name ];

    $c->redirect( $c->uri_for( $c->controller->action_for("menu"), [ $section ] ) );
}

sub transfer :Chained('base') :PathPart('delete') :Args(3) {
    my ( $self, $c, $section, $type, $template_name ) = @_;

    $template_name =~ /[\/\\;:'"]/
        and die("Bad characters in template name: $template_name");

    grep { $section eq $_ } @valid_sections
        or die("Invalid template section: $section");

    grep { $type eq $_ } @valid_types
        or die("Invalid template type: $type");

    my $sandbox_dir = get_site_base_dir( $section, $type, $c->site, 'sandbox' );
    my $active_dir  = get_site_base_dir( $section, $type, $c->site, 'active'  );

    -e "${sandbox_dir}/${template_name}"
        or die("Unable to find template file to copy");

    # Backup any existing active template
    my ( $sec, $min, $hour, $mday, $mon, $year ) = localtime(time);
    $mon++;
    $year += 1900;
    my $timestamp = "${year}-${mon}-${mday}_${hour}:${min}:${sec}";
    -e "${active_dir}/${template_name}"
        and `mv ${active_dir}/${template_name} ${active_dir}/${template_name}.$timestamp`;

    `cp ${sandbox_dir}/${template_name} ${active_dir}/${template_name}`;

    $c->flash->{results} = [ $c->loc('Transfered template: ') . $template_name ];

    $c->redirect( $c->uri_for( $c->controller->action_for("menu"), [ $section ] ) );
}








sub get_base_dir {
    my ( $section, $type ) = @_;

    my %dir_map = (
        cjdb4 => {
            css        => $CUFTS::Config::CJDB4_CSS_DIR,
            template   => $CUFTS::Config::CJDB4_TEMPLATE_DIR,
        },
        crdb4 => {
            css        => $CUFTS::Config::CRDB4_CSS_DIR,
            template   => $CUFTS::Config::CRDB4_TEMPLATE_DIR,
        },
    );

    return $dir_map{$section}->{$type};
}

sub get_site_base_dir {
    my ( $section, $type, $site ) = ( shift, shift, shift );
    my @path_parts = @_;

    my %dir_map = (
        cjdb4 => {
            css      => [ $CUFTS::Config::CJDB4_SITE_CSS_DIR, $site->id, 'static', 'css' ],
            template => [ $CUFTS::Config::CJDB4_SITE_TEMPLATE_DIR, $site->id ],
        },
        crdb4 => {
            css      => [ $CUFTS::Config::CRDB4_SITE_CSS_DIR, $site->id, 'static', 'css' ],
            template => [ $CUFTS::Config::CRDB4_SITE_TEMPLATE_DIR, $site->id ],
        },
    );

    my $path;
    foreach my $part ( @{$dir_map{$section}->{$type}}, @path_parts ) {
        if ( defined($path) && $path !~ m{/$} ) {
            $path .= '/';
        }
        $path .= $part;
        _build_path($path);
    }

   # warn($path);
    return $path;
}

sub get_site_url {
    my ( $section, $site, $status ) = @_;

    my %base_urls = (
        cjdb4 => $CUFTS::Config::CJDB4_URL,
        crdb4 => $CUFTS::Config::CRDB4_URL,
    );

    my $url = $base_urls{$section} . $site->key;
    $url .= '!sandbox' if $status eq 'sandbox';
    $url .= '/';

    return $url;
}

sub _build_path {
    my $path = shift;

    -d $path
        or mkdir $path
            or die(qq{Unable to create directory "$path": $!});

    return $path;
}


=encoding utf8

=head1 AUTHOR

Todd Holbrook

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
