#!/usr/local/bin/perl

use lib qw(lib);

use CUFTS::Exceptions;
use CUFTS::Config;
use URI::Escape qw(uri_escape);
use File::Path;
use String::Util qw(trim hascontent);
use Getopt::Long;

use strict;

# Read command line arguments

my %options;
GetOptions(\%options, 'site_key=s', 'site_id=i', 'global');

# Check for necessary arguments

if ( !(defined($options{site_key}) || defined($options{site_id})) && !defined($options{global}) ) {
    usage();
    exit;
}

my $schema = CUFTS::Config::get_schema();

# Get CUFTS site id

my ( $outfile, $path, $site );

if ( defined $options{global} ) {
    print "Creating global subject browse page\n";
    $path = "${CUFTS::Config::CJDB_TEMPLATE_DIR}/";
} else {
    $site = get_site($schema);
    my $site_id = $site->id;
    $path = "${CUFTS::Config::CJDB_SITE_TEMPLATE_DIR}/${site_id}/active/";
    print "Creating subject browse page for site: ", $site->key, "\n";
}
$outfile = $path . 'lcc_browse_content.tt';

if ( ! -e $path ) {
    print "Path to template does not exist, attempting to create: $path\n";
    mkpath($path) or
        die("Unable to creat path!\n");
}


open OUTFILE, ">$outfile" or
    CUFTS::Exception::App->throw("Unable to open file (${outfile}) for writing: $!");

print "Writing LCC subject guide browse file: $outfile\n";

my $search = {};
if (defined($site)) {
    $search->{site} = $site->id;
} else {
    $search->{site} = undef;
}

my $subjects_rs = $schema->resultset('CJDBLCCSubjects')->search($search);
my %subject_hierarchy;

my $found_subjects_count = 0;
while (my $subject = $subjects_rs->next) {
    $found_subjects_count++;
    if (defined($subject->subject3) && $subject->subject3 ne '') {
        $subject_hierarchy{$subject->subject1}->{$subject->subject2}->{$subject->subject3} = {};
    } elsif (defined($subject->subject2) && $subject->subject2 ne '') {
        exists($subject_hierarchy{$subject->subject1}->{$subject->subject2}) or
            $subject_hierarchy{$subject->subject1}->{$subject->subject2} = {};
    } elsif (defined($subject->subject1) && $subject->subject1 ne '') {
        exists($subject_hierarchy{$subject->subject1}) or
            $subject_hierarchy{$subject->subject1} = {};
    }
}

if ( $found_subjects_count == 0 ) {
    print "No subjects found in the LCCSubjects table\n";
}

print OUTFILE "[% USE url %]\n";
print OUTFILE "<div id=\"lcc-browse-content\">\n";
my ($count1, $count2) = (0,0);

foreach my $subject1 (sort keys %subject_hierarchy) {

    $count1++;
    my $subclasses1 = scalar(keys %{$subject_hierarchy{$subject1}});
    my $subject1_uri = uri_escape($subject1);

    print OUTFILE "<div class=\"lcc-browse1\">";

    if ($subclasses1) {
        print OUTFILE "<a href=\"#subject-group${count1}\" id=\"lcc-browse-group${count1}-button\" onClick=\"return simpleHideClick('lcc-browse-group${count1}', 'lcc-browse2-group-visible', 'lcc-browse2-group-hidden', 'lcc-browse-group${count1}-buttonimage', '[% image_dir %]plus.gif', '[% image_dir %]minus.gif')\">";
        print OUTFILE "<img name=\"lcc-browse-group${count1}-buttonimage\" src=\"[% image_dir %]plus.gif\" />";
        print OUTFILE "</a> ";
    } else {
        print OUTFILE "<img src=\"[% image_dir %]spacer.gif\" style=\"width: 16px; height: 11px\" />";
    }

    print OUTFILE "<a href=\"[% url(\"\$url_base/browse/journals?search_terms=${subject1_uri}&browse_field=subject\") %]\">${subject1}</a>";

    print OUTFILE "</div>\n";

    if ($subclasses1) {
        print OUTFILE "<div id=\"lcc-browse-group${count1}\" class=\"lcc-browse2-group-hidden\">\n";
    }

    foreach my $subject2 (sort keys %{$subject_hierarchy{$subject1}}) {

        my $subclasses2 = scalar(keys %{$subject_hierarchy{$subject1}->{$subject2}});
        my $subject2_uri = uri_escape($subject2);

        print OUTFILE "<div class=\"lcc-browse2\"><a href=\"[% url(\"\$url_base/browse/journals?search_terms=${subject2_uri}&browse_field=subject\") %]\">${subject2}</a></div>\n";

        foreach my $subject3 (sort keys %{$subject_hierarchy{$subject1}->{$subject2}}) {

            my $subject3_uri = uri_escape($subject3);

            print OUTFILE "<div class=\"lcc-browse3\"><a href=\"[% url(\"\$url_base/browse/journals?search_terms=${subject3_uri}&browse_field=subject\") %]\">${subject3}</a></a></div>\n";
        }
    }

    if ($subclasses1) {
        print OUTFILE "</div>\n";
    }


}

print OUTFILE "</div>\n";
close OUTFILE;

print "Finished load, file closed\n";

exit;

sub get_site {
    my ( $schema ) = @_;

    my $site;

    if ( hascontent($options{site_id}) ) {
        $site = $schema->resultset('Sites')->find({ id => $options{site_id} });
    }
    elsif ( hascontent($options{site_key}) )   {
        $site = $schema->resultset('Sites')->find({ key => $options{site_key} });
    }

    defined($site) or
        CUFTS::Exception::App->throw('Site is undefined in get_site.');

    return $site;
}


sub usage {
    print <<EOF;

create_subject_browse - creates the LC call number browse for CJDB

 site_key=XXX - CUFTS site key (example: BVAS)
 site_id=111  - CUFTS site id (example: 23)
 global       - builds the global list (has precedence over site parameters)

EOF
}
