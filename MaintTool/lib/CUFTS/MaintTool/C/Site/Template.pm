package CUFTS::MaintTool::C::Site::Template;

use strict;
use base 'Catalyst::Base';

my @valid_states = ( 'active', 'sandbox' );
my @valid_types  = ( 'crdb_css', 'cjdb_css', 'cjdb_template', 'crdb_template',
                     'crdb4_css', 'cjdb4_css', 'cjdb4_template', 'crdb4_template', );

my $form_validate = {
    optional => [ 'submit', 'cancel', 'template_contents' ],
    filters  => ['trim'],
};

sub auto : Private {
    my ( $self, $c ) = @_;
    $c->stash->{section} = 'templates';
}

sub menu_cjdb : Local {
    my ( $self, $c ) = @_;

    my $site = $c->stash->{current_site};

    ##
    ## Get CJDB template files, active, and sandbox lists
    ##

    my @cjdb_template_list = qw(
        account_create.tt
        account_manage.tt
        azmenu.tt
        browse.tt
        browse_associations.tt
        browse_form.tt
        browse_form_alt.tt
        browse_journals.tt
        browse_journals_new.tt
        browse_journals_unified_data.tt
        browse_search_description.tt
        browse_subjects.tt
        errors.tt
        journal.tt
        journal_associations.tt
        journal_availability.tt
        journal_issns.tt
        journal_mytags.tt
        journal_relations.tt
        journal_subjects.tt
        journal_tags.tt
        journal_titles.tt
        journals_link_label.tt
        journals_link_name.tt
        layout.tt
        lcc_browse.tt
        lcc_browse_content.tt
        loggedin.tt
        login.tt
        manage_tags_info.tt
        menu.tt
        mytags.tt
        nav_line.tt
        page_footer.tt
        page_header.tt
        page_title.tt
        paging.tt
        paging_new.tt
        selected_journals.tt
        selected_journals_data.tt
        setup_browse.tt
        setup_browse_javascript.tt
        tag_viewing_string.tt
    );

    my $cjdb_active_dir  = get_site_base_dir('cjdb_template', $site, '/active');
    my $cjdb_sandbox_dir = get_site_base_dir('cjdb_template', $site, '/sandbox');

    opendir ACTIVE, $cjdb_active_dir
        or die('Unable to open CJDB site active template directory for reading');
    my @cjdb_active_templates = grep !/^\./, readdir ACTIVE;
    closedir ACTIVE;

    opendir SANDBOX, $cjdb_sandbox_dir
        or die('Unable to open CJDB site sandbox template directory for reading');
    my @cjdb_sandbox_templates = grep !/^\./, readdir SANDBOX;
    closedir SANDBOX;

    ##
    ## Get CSS files, active and sandbox lists
    ##

    my @cjdb_css_list        = qw( cjdb.css );
    my $cjdb_active_css_dir  = get_site_base_dir( 'cjdb_css', $site, 'active'  );
    my $cjdb_sandbox_css_dir = get_site_base_dir( 'cjdb_css', $site, 'sandbox' );

    opendir ACTIVE, $cjdb_active_css_dir
        or die('Unable to open CJDB site active CSS directory for reading');
    my @cjdb_active_css = grep !/^\./, readdir ACTIVE;
    closedir ACTIVE;

    opendir SANDBOX, $cjdb_sandbox_css_dir
        or die('Unable to open CJDB site sandbox CSS directory for reading');
    my @cjdb_sandbox_css = grep !/^\./, readdir SANDBOX;
    closedir SANDBOX;

    $c->stash->{cjdb_url} = $CUFTS::Config::CJDB_URL;

    $c->stash->{active_templates}   = \@cjdb_active_templates;
    $c->stash->{sandbox_templates}  = \@cjdb_sandbox_templates;
    $c->stash->{templates}          = \@cjdb_template_list;

    $c->stash->{csses}         = \@cjdb_css_list;
    $c->stash->{active_csses}  = \@cjdb_active_css;
    $c->stash->{sandbox_csses} = \@cjdb_sandbox_css;

    $c->stash->{active_url}  = $CUFTS::Config::CJDB_URL . $site->key . '/set_box/active';
    $c->stash->{sandbox_url} = $CUFTS::Config::CJDB_URL . $site->key . '/set_box/sandbox';

    $c->stash->{header_section} = 'CJDB Templates';

    $c->stash->{type} = 'cjdb';
    $c->stash->{template} = 'site/template/menu.tt';
}


sub menu_cjdb4 : Local {
    my ( $self, $c ) = @_;

    my $site = $c->stash->{current_site};

    ##
    ## Get CJDB template files, active, and sandbox lists
    ##

    my @cjdb_template_list = qw(
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
    );

    my $cjdb_active_dir  = get_site_base_dir('cjdb4_template', $site, '/active');
    my $cjdb_sandbox_dir = get_site_base_dir('cjdb4_template', $site, '/sandbox');

    opendir ACTIVE, $cjdb_active_dir
        or die('Unable to open CJDB4 site active template directory for reading');
    my @cjdb_active_templates = grep !/^\./, readdir ACTIVE;
    closedir ACTIVE;

    opendir SANDBOX, $cjdb_sandbox_dir
        or die('Unable to open CJDB4 site sandbox template directory for reading');
    my @cjdb_sandbox_templates = grep !/^\./, readdir SANDBOX;
    closedir SANDBOX;

    ##
    ## Get CSS files, active and sandbox lists
    ##

    my @cjdb_css_list        = qw( cjdb.css );
    my $cjdb_active_css_dir  = get_site_base_dir( 'cjdb4_css', $site, 'active'  );
    my $cjdb_sandbox_css_dir = get_site_base_dir( 'cjdb4_css', $site, 'sandbox' );

    opendir ACTIVE, $cjdb_active_css_dir
        or die('Unable to open CJDB site active CSS directory for reading');
    my @cjdb_active_css = grep !/^\./, readdir ACTIVE;
    closedir ACTIVE;

    opendir SANDBOX, $cjdb_sandbox_css_dir
        or die('Unable to open CJDB site sandbox CSS directory for reading');
    my @cjdb_sandbox_css = grep !/^\./, readdir SANDBOX;
    closedir SANDBOX;

    $c->stash->{cjdb_url} = $CUFTS::Config::CJDB4_URL;

    $c->stash->{active_templates}   = \@cjdb_active_templates;
    $c->stash->{sandbox_templates}  = \@cjdb_sandbox_templates;
    $c->stash->{templates}          = \@cjdb_template_list;

    $c->stash->{csses}         = \@cjdb_css_list;
    $c->stash->{active_csses}  = \@cjdb_active_css;
    $c->stash->{sandbox_csses} = \@cjdb_sandbox_css;

    $c->stash->{active_url}  = $CUFTS::Config::CJDB4_URL . $site->key . '/set_box/active';
    $c->stash->{sandbox_url} = $CUFTS::Config::CJDB4_URL . $site->key . '/set_box/sandbox';

    $c->stash->{header_section} = 'CJDB4 Templates';

    $c->stash->{type} = 'cjdb4';
    $c->stash->{template} = 'site/template/menu.tt';
}


sub menu_crdb : Local {
    my ( $self, $c ) = @_;

    my $site = $c->stash->{current_site};

    ##
    ## Get CRDB template files, active, and sandbox lists
    ##

    my @crdb_template_list = qw(
        account_create.tt
        account_manage.tt
        browse.tt
        browse_js.tt
        current_facets.tt
        display_field.tt
        errors.tt
        facet_labels.tt
        facet_menu.tt
        facet_menu_js.tt
        fatal_error.tt
        group_record_field.tt
        layout.tt
        loggedin.tt
        login.tt
        main.tt
        menu.tt
        mobile_app_footer.tt
        mobile_app_header.tt
        mobile_app_js_setup.tt
        mobile_app.tt
        nav_line.tt
        page_footer.tt
        page_header.tt
        page_title.tt
        resource.tt
    );

    my $crdb_active_dir  = get_site_base_dir('crdb_template', $site, '/active');
    my $crdb_sandbox_dir = get_site_base_dir('crdb_template', $site, '/sandbox');

    opendir ACTIVE, $crdb_active_dir
        or die('Unable to open CRDB site active template directory for reading');
    my @crdb_active_templates = grep !/^\./, readdir ACTIVE;
    closedir ACTIVE;

    opendir SANDBOX, $crdb_sandbox_dir
        or die('Unable to open CRDB site sandbox template directory for reading');
    my @crdb_sandbox_templates = grep !/^\./, readdir SANDBOX;
    closedir SANDBOX;

    ##
    ## Get CSS files, active and sandbox lists
    ##

    my @crdb_css_list        = qw( crdb.css crdb_mobile.css );
    my $crdb_active_css_dir  = get_site_base_dir( 'crdb_css', $site, 'active'  );
    my $crdb_sandbox_css_dir = get_site_base_dir( 'crdb_css', $site, 'sandbox' );

    opendir ACTIVE, $crdb_active_css_dir
        or die('Unable to open CRDB site active CSS directory for reading');
    my @crdb_active_css = grep !/^\./, readdir ACTIVE;
    closedir ACTIVE;

    opendir SANDBOX, $crdb_sandbox_css_dir
        or die('Unable to open CRDB site sandbox CSS directory for reading');
    my @crdb_sandbox_css = grep !/^\./, readdir SANDBOX;
    closedir SANDBOX;

    $c->stash->{crdb_url} = $CUFTS::Config::CRDB_URL;

    $c->stash->{templates}          = \@crdb_template_list;
    $c->stash->{active_templates}   = \@crdb_active_templates;
    $c->stash->{sandbox_templates}  = \@crdb_sandbox_templates;

    $c->stash->{csses}         = \@crdb_css_list;
    $c->stash->{active_csses}  = \@crdb_active_css;
    $c->stash->{sandbox_csses} = \@crdb_sandbox_css;

    $c->stash->{active_url}  = $CUFTS::Config::CRDB_URL . $site->key . '/set_box/active';
    $c->stash->{sandbox_url} = $CUFTS::Config::CRDB_URL . $site->key . '/set_box/sandbox';

    $c->stash->{header_section} = 'CRDB Templates';

    $c->stash->{type} = 'crdb';
    $c->stash->{template} = 'site/template/menu.tt';
}

sub menu_crdb4 : Local {
    my ( $self, $c ) = @_;

    my $site = $c->stash->{current_site};

    ##
    ## Get CRDB template files, active, and sandbox lists
    ##

    my @crdb_template_list = qw(
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
    );

    my $crdb_active_dir  = get_site_base_dir('crdb4_template', $site, '/active');
    my $crdb_sandbox_dir = get_site_base_dir('crdb4_template', $site, '/sandbox');

    opendir ACTIVE, $crdb_active_dir
        or die('Unable to open CRDB4 site active template directory for reading');
    my @crdb_active_templates = grep !/^\./, readdir ACTIVE;
    closedir ACTIVE;

    opendir SANDBOX, $crdb_sandbox_dir
        or die('Unable to open CRDB4 site sandbox template directory for reading');
    my @crdb_sandbox_templates = grep !/^\./, readdir SANDBOX;
    closedir SANDBOX;

    ##
    ## Get CSS files, active and sandbox lists
    ##

    my @crdb_css_list        = qw( crdb.css );
    my $crdb_active_css_dir  = get_site_base_dir( 'crdb4_css', $site, 'active'  );
    my $crdb_sandbox_css_dir = get_site_base_dir( 'crdb4_css', $site, 'sandbox' );

    opendir ACTIVE, $crdb_active_css_dir
        or die('Unable to open CRDB site active CSS directory for reading');
    my @crdb_active_css = grep !/^\./, readdir ACTIVE;
    closedir ACTIVE;

    opendir SANDBOX, $crdb_sandbox_css_dir
        or die('Unable to open CRDB site sandbox CSS directory for reading');
    my @crdb_sandbox_css = grep !/^\./, readdir SANDBOX;
    closedir SANDBOX;

    $c->stash->{crdb_url} = $CUFTS::Config::CRDB4_URL;

    $c->stash->{templates}          = \@crdb_template_list;
    $c->stash->{active_templates}   = \@crdb_active_templates;
    $c->stash->{sandbox_templates}  = \@crdb_sandbox_templates;

    $c->stash->{csses}         = \@crdb_css_list;
    $c->stash->{active_csses}  = \@crdb_active_css;
    $c->stash->{sandbox_csses} = \@crdb_sandbox_css;

    $c->stash->{active_url}  = $CUFTS::Config::CRDB4_URL . $site->key . '/';
    $c->stash->{sandbox_url} = $CUFTS::Config::CRDB4_URL . $site->key . '!sandbox/';

    $c->stash->{header_section} = 'CRDB4 Templates';

    $c->stash->{type} = 'crdb4';
    $c->stash->{template} = 'site/template/menu.tt';
}




sub view : Local {
    my ( $self, $c, $type, $template_name, $state ) = @_;
    $c->stash->{template}      = 'site/template/view.tt';
    $c->stash->{type}          = $type;
    $c->stash->{state}         = $state;
    $c->stash->{template_name} = $template_name;
    $c->forward("/site/template/handle");
}

sub edit : Local {
    my ( $self, $c, $type, $template_name ) = @_;
    $c->stash->{template}      = 'site/template/edit.tt';
    $c->stash->{type}          = $type;
    $c->stash->{state}         = 'sandbox';
    $c->stash->{template_name} = $template_name;
    $c->forward("/site/template/handle");
}

sub handle : Private {
    my ( $self, $c ) = @_;

    my $state         = $c->stash->{state};
    my $type          = $c->stash->{type};
    my $template_name = $c->stash->{template_name};

    grep { $state eq $_ } @valid_states
        or die("Invalid template state: $state");

    grep { $type eq $_ } @valid_types
        or die("Invalid template type: $type");

    $template_name =~ /[\/\\;:'"]/   # Fix this, make it only tax a-z_. - Todd, 2009-04-27
        and die("Bad characters in template name: $template_name");

    my $base_dir = get_base_dir($type);
    my $site_dir = get_site_base_dir($type, $c->stash->{current_site}, $state);

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
    $c->stash->{type}              = $type;
    $c->stash->{template_contents} = $template_contents;
    $c->stash->{state}             = $state;
}

sub save : Local {
    my ( $self, $c, $type, $template_name ) = @_;

    if ( $c->req->param('cancel') ) {
        $c->redirect('/site/template/menu');
    }

    $c->form($form_validate);

    grep { $type eq $_ } @valid_types
        or die("Invalid template type: $type");

    $template_name =~ /[\/\\;:'"]/
        and die("Bad characters in template name: $template_name");

    if (   $c->form->has_missing
        || $c->form->has_invalid
        || $c->form->has_unknown )
    {
        die('Error with edit form');
    }

    my $site_dir = get_site_base_dir( $type, $c->stash->{current_site}, 'sandbox' );

    open TEMPLATE, ">${site_dir}/${template_name}"
        or die("Unable to open template file: $!");
    print TEMPLATE $c->form->valid->{template_contents};
    close TEMPLATE;

    $c->stash->{results} = 'File saved.';

    my $forward_type = $type;
    $forward_type =~ s/_.+$//;
    $c->redirect("/site/template/menu_${forward_type}");
}

sub delete : Local {
    my ( $self, $c, $type, $template_name, $state ) = @_;

    grep { $state eq $_ } @valid_states
        or die("Invalid template state: $state");

    grep { $type eq $_ } @valid_types
        or die("Invalid template type: $type");

    $template_name =~ /[\/\\;:'"]/
        and die("Bad characters in template name: $template_name");

    my $site_dir = get_site_base_dir($type, $c->stash->{current_site}, $state);

    -e "${site_dir}/${template_name}"
            and unlink "${site_dir}/${template_name}"
                or die("Unable to unlink template file '${site_dir}/${template_name}': $!");

    my $forward_type = substr($type,0,4);
    $c->redirect("/site/template/menu_${forward_type}");
}

sub transfer : Local {
    my ( $self, $c, $type, $template_name ) = @_;

    $template_name =~ /[\/\\;:'"]/
        and die("Bad characters in template name: $template_name");

    grep { $type eq $_ } @valid_types
        or die("Invalid template type: $type");

    my $sandbox_dir = get_site_base_dir( $type, $c->stash->{current_site}, 'sandbox' );
    my $active_dir  = get_site_base_dir( $type, $c->stash->{current_site}, 'active'  );

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

    my $forward_type = substr($type,0,4);
    $c->redirect("/site/template/menu_${forward_type}");
}

sub get_base_dir {
    my ($type) = @_;

    if ( $type eq 'cjdb_css' ) {
        return $CUFTS::Config::CJDB_CSS_DIR;
    }
    elsif ( $type eq 'cjdb_template' ) {
        return $CUFTS::Config::CJDB_TEMPLATE_DIR;
    }
    if ( $type eq 'cjdb4_css' ) {
        return $CUFTS::Config::CJDB4_CSS_DIR;
    }
    elsif ( $type eq 'cjdb4_template' ) {
        return $CUFTS::Config::CJDB4_TEMPLATE_DIR;
    }
    elsif ( $type eq 'crdb_css' ) {
        return $CUFTS::Config::CRDB_CSS_DIR;
    }
    elsif ( $type eq 'crdb_template' ) {
        return $CUFTS::Config::CRDB_TEMPLATE_DIR;
    }
}

sub get_site_base_dir {
    my $type = shift;
    my $site = shift;
    my @path_parts = @_;

    my %dir_map = (
        cjdb_css            => [ $CUFTS::Config::CJDB_SITE_CSS_DIR, $site->id, 'static', 'css' ],
        cjdb_template       => [ $CUFTS::Config::CJDB_SITE_TEMPLATE_DIR, $site->id ],

        cjdb4_css           => [ $CUFTS::Config::CJDB4_SITE_CSS_DIR, $site->id, 'static', 'css' ],
        cjdb4_template      => [ $CUFTS::Config::CJDB4_SITE_TEMPLATE_DIR, $site->id ],

        crdb_css            => [ $CUFTS::Config::CRDB_SITE_CSS_DIR, $site->id, 'static', 'css' ],
        crdb_template       => [ $CUFTS::Config::CRDB_SITE_TEMPLATE_DIR, $site->id ],

        crdb4_css           => [ $CUFTS::Config::CRDB4_SITE_CSS_DIR, $site->id, 'static', 'css' ],
        crdb4_template      => [ $CUFTS::Config::CRDB4_SITE_TEMPLATE_DIR, $site->id ],
    );

    my $path;
    foreach my $part ( @{$dir_map{$type}}, @path_parts ) {
        if ( defined($path) && $path !~ m{/$} ) {
            $path .= '/';
        }
        $path .= $part;
        _build_path($path);
    }

   # warn($path);
    return $path;
}



sub _build_path {
    my $path = shift;

    -d $path
        or mkdir $path
            or die(qq{Unable to create directory "$path": $!});

    return $path;
}

=head1 NAME

CUFTS::MaintTool::C::Site::Template - Component for site templates

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

