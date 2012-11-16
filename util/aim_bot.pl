use strict;

use lib 'lib';

use Net::OSCAR qw(:standard);

use CUFTS::DB::Resources;
use CUFTS::DB::Journals;
use CUFTS::DB::JournalsAuth;
use CUFTS::DB::LocalResources;
use CUFTS::DB::LocalJournals;
use CUFTS::Resolve;

use CUFTS::Util::Simple;

use Term::ReadLine;
use HTML::TagFilter;
use Getopt::Long;

use Data::Dumper;

my %options;
GetOptions(\%options, 'offline');

my $screenname = 'CUFTS2';
my $password   = 'CUFTS4lib';
my $max_length = 440;

my $actions = {
    'search'   => \&search,
    'more'     => \&more,
    'select'   => \&select_result,
    'results'  => \&results,
    'coverage' => \&coverage,
    'current'  => \&current,
    'issns'    => \&issns,
    'titles'   => \&titles,
    'marc'     => \&marc,
    'urls'     => \&resolve,
    'full'     => \&full,
    'help'     => \&help,
    'site'     => \&site,

    '_dump_cache' => \&_dump_cache,
};

my $cache = {};

my $tf = new HTML::TagFilter;

if ( $options{offline} ) {
    offline();
} else {
    online();
}

sub offline {
    my $term = Term::ReadLine->new('Term');
    my $input = $term->readline(': ');

    while ($input) {
        $input = trim_string(filter($input));
        my ( $action, $rest ) = parse_message($input);
        my $response = handle( $action, $rest, 'offline' );
        print $response;
        $input = $term->readline(': ');
    }

    return 1;
}

sub online {
    my $oscar = Net::OSCAR->new();
    $oscar->set_callback_im_in( \&im_in );
    $oscar->signon( $screenname, $password );

    while (1) {
        eval { $oscar->do_one_loop(); };
        if ($@) {
            warn($@);
        }
    }

    return 1;
}

sub filter {
    my ($input) = @_;
    return $tf->filter($input);
}

sub im_in {
    my ( $oscar, $sender, $message, $is_away ) = @_;

    $message = trim_string(filter($message));

    my ( $action, $rest ) = parse_message($message);
    my $response = handle( $action, $rest );

    $oscar->send_im( $sender, $response );
}

sub handle {
    my ( $action, $rest, $sender ) = @_;

    print "action: $action\nrest:$rest\n";
    my $action_sub = dispatch($action);

    if ( !defined($action_sub) ) {
        warn("Invalid action: $action");
        return;
    }

    my $response = &$action_sub( $rest, $sender );

    return trim_output( $response, $sender );
}

sub trim_output {
    my ( $string, $sender ) = @_;
    
    if ( length($string) < $max_length ) {
        $cache->{$sender}->{out} = '';
        return $string;
    }
    
    my $pos = rindex( $string, "\n", $max_length );
    if ($pos == -1) {
        $pos = $max_length;
    }
    
    my $send = substr( $string, 0, $pos+1 );
    $send .= "\n( more )\n";

    my $remainder = substr( $string, $pos+1 );
    $cache->{$sender}->{out} = $remainder;

    return $send;
}



sub parse_message {
    my ($message) = @_;

    my ( $action, $rest ) = split( / /, $message, 2 );
    return ( ( $action, $rest ) );
}

sub dispatch {
    my ($action) = @_;

    return $actions->{$action};
}


sub search {
    my ( $string, $sender ) = @_;

    my @jas;

    # If it looks like an ISSN, search it as an ISSN, otherwise check for an
    # "exact" keyword for an exact title search, otherwise do a truncated
    # title search
    if ( $string =~ /^\d{4}-?\d{3}[\dxX]$/ ) {
        @jas = CUFTS::DB::JournalsAuth->search_by_issns($string);
    }
    elsif ( $string =~ s/^exact\s+// ) {
        @jas = CUFTS::DB::JournalsAuth->search_by_title($string);
    }
    else {
        $string = "$string%";
        @jas = CUFTS::DB::JournalsAuth->search_by_title($string);
    }

    if ( !scalar(@jas) ) {
        return "No hits found in the CUFTS database for that search.\n";
    }

    if ( scalar(@jas) > 20 ) {
        return "Too many results (>20) for that search. Please refine your search term.\n";
    }

    @jas = sort { $a->title cmp $b->title } @jas;
    $cache->{$sender}->{jas} = \@jas;

    return results( '', $sender );
}

sub results {
    my ( $string, $sender ) = @_;
    
    my $results = $cache->{$sender}->{jas};
    if ( !defined($results) || !scalar(@$results) ) {
        return "No current search results.\n";
    }

    my $out;
    my $count = 0;

    foreach my $ja (@$results) {
        my @issns = $ja->issns;
        my $issn_string = join ', ', map {$_->issn_dash} @issns;
        $out .= ++$count . ": " . $ja->title;
        if ( $issn_string ne '') {
            $out .= " [$issn_string]";
        }
        $out .= "\n";
    }

    return $out;
}

sub select_result {
    my ( $string, $sender ) = @_;
    
    if ( $string !~ /^\s*(\d+)\s*$/ ) {
        return "No result number in request\n";
    }

    my ( $current, $result, $message ) = _select( $string, $sender, 1 );
    
    if ( $current > 0 ) {
        return "Current selection: $current: " . $result->title . "\n";
    }
    else {
        return $message;
    }
}

sub _select {
    my ( $string, $sender, $set ) = @_;

    my $results = $cache->{$sender}->{jas};
    if ( !defined($results) || !scalar(@$results) ) {
        return (0, undef, "No current search results.\n");
    }

    my $current = $cache->{$sender}->{current} || 0;
    if ( $string =~ /^\s*(\d+)\s*$/ ) {
        $current = $1;
    }
    my $index = $current - 1;

    if ( $current > 0 ) {
        if ( !defined($results->[$index]) ) {
            return (0, undef, "No matching result in current result set.\n");
        }

        if ( $set ) {
            $cache->{$sender}->{current} = $current;
        }
        
        return ($current, $results->[$index], '');
    }
    else {
        return return (0, undef, "No current result selected\n");
    }
}

sub marc {
    my ( $string, $sender ) = @_;

    my ( $current, $result, $message ) = _select( $string, $sender );
    if ( !$current ) {
        return $message;
    }
    
    if ( $result->marc ) {
        return $result->marc_object->as_formatted . "\n";
    }
    else {
        return "No MARC information for that record.\n"
    }
    
}


sub coverage {
    my ( $string, $sender ) = @_;

    my ( $current, $result, $message ) = _select( $string, $sender );
    if ( !$current ) {
        return $message;
    }

    my $out;

    foreach my $gj ( sort { $a->resource->name cmp $b->resource->name } $result->global_journals ) {

#       print($gj->resource->name . ' - ' . $gj->resource->provider . "\n");

        $out .= $gj->resource->name . ' - '
             .  $gj->resource->provider . "\n";

        my $ft_coverage  = get_cufts_ft_coverage($gj);
        my $cit_coverage = get_cufts_cit_coverage($gj);
        my $coverage;
        
#        print("FT: $ft_coverage\nCT: $cit_coverage\n");

        if ( length($ft_coverage) ) {
            $ft_coverage =~ s/\n/; /g;
            $coverage .= "      fulltext: $ft_coverage\n";
        }
        if ( length($cit_coverage) ) {
            $cit_coverage =~ s/\n/; /g;
            $coverage .= "      citation: $cit_coverage\n";
        }

        if ( is_empty_string($coverage) ) {
            $coverage = "   No coverage information available.\n";
        }

        $out .= $coverage;

    }

    if ( is_empty_string($out) ) {
        $out = 'No online sources for that journal found.'
    }

    return $out;
}

sub resolve {
    my ( $string, $sender ) = @_;

    my $open = $string =~ s/\s*open\s*// ? 1 : 0;  # Only show open access URLs?

    my ( $current, $result, $message ) = _select( $string, $sender );
    if ( !$current ) {
        return $message;
    }
    
    my $out;

GLOBAL_JOURNAL:
    foreach my $gj ( sort { $a->resource->name cmp $b->resource->name } $result->global_journals ) {

        my $url = get_url($gj, $sender, $open);
        if ( not_empty_string($url) ) {
            $out .= $gj->resource->name . ' - '
                 .  $gj->resource->provider . "\n"
                 . $url . "\n";
        }
    }
    
    if ( is_empty_string($out) ) {
        $out = 'No ';
        if ($open) {
            $out .= ' open access ';
        }
        $out .= "URLs were found for that journal.\n"
    }

    if ( is_empty_string($out) ) {
        $out = "No online sources for that journal found.\n";
    }
    
    return $out;
}

sub full {
    my ( $string, $sender ) = @_;

    my $open = $string =~ s/\s*open\s*// ? 1 : 0;  # Only show open access URLs?

    my ( $current, $result, $message ) = _select( $string, $sender );
    if ( !$current ) {
        return $message;
    }

    my $out;

    warn($result->id);

    foreach my $gj ( sort { $a->resource->name cmp $b->resource->name } $result->global_journals ) {

        $out .= $gj->resource->name . ' - '
             .  $gj->resource->provider . "\n";

        my $ft_coverage  = get_cufts_ft_coverage($gj);
        my $cit_coverage = get_cufts_cit_coverage($gj);
        my $url = get_url($gj, $sender, $open);
        my $coverage;
    
        if ( not_empty_string($ft_coverage) ) {
            $ft_coverage =~ s/\n/; /g;
            $coverage .= "   fulltext: $ft_coverage\n";
        }
        if ( not_empty_string($cit_coverage) ) {
            $cit_coverage =~ s/\n/; /g;
            $coverage .= "   citation: $cit_coverage\n";
        }
        if ( not_empty_string($url) ) {
            $coverage .= "   $url\n";
        }

        if ( is_empty_string($coverage) ) {
            $coverage = "   No coverage information available.\n";
        }

        $out .= $coverage;
    }

    if ( is_empty_string($out) ) {
        $out = "No online sources for that journal found.\n";
    }

    return $out;
    
}

sub issns {
    my ( $string, $sender ) = @_;

    my ( $current, $result, $message ) = _select( $string, $sender );
    if ( !$current ) {
        return $message;
    }
    
    my @issns = $result->issns;
    if ( !scalar(@issns) ) {
        return "No known ISSNs for that journal.\n";
    }
    
    return join("\n", map {$_->issn_dash} @issns) . "\n";
}

sub titles {
    my ( $string, $sender ) = @_;

    my ( $current, $result, $message ) = _select( $string, $sender );
    if ( !$current ) {
        return $message;
    }
    
    my @titles = $result->titles;
    return join("\n", map {$_->title} @titles) . "\n";
}


sub current {
    my ( $string, $sender ) = @_;

    my ( $current, $result, $message ) = _select( $string, $sender );
    if ( $current > 0 ) {
        return "Current selection: $current: " . $result->title . "\n";
    }
    else {
        return $message;
    }
}

sub site {
    my ( $string, $sender ) = @_;
    
    if ( is_empty_string($string) ) {
        if ( defined($cache->{$sender}->{site}) ) {
            return "Current site is: " . $cache->{$sender}->{site}->name . "\n";
        } else {
            return "No current site\n";
        }
    }
    
    my $site = CUFTS::DB::Sites->search('key' => $string)->first;
    if ( defined($site) ) {
        $cache->{$sender}->{site} = $site;
        return "Current site is: " . $site->name . "\n";
    }
    else {
        return "Unable to find site key '$string'";
    }
}

sub more {
    my ( $string, $sender ) = @_;
    my $return = $cache->{$sender}->{out};
    if ( length($return) == 0 ) {
        $return = "No more to return.\n";
    }
    return $return;
}


sub help {
    my ( $string, $sender ) = @_;
    
    if ( $string =~ /search/ ) {
        return << "EOL";
search ( [exact] title | issn )
  Searches for journals by ISSN or title.  If 'exact' keyword is included then title searches will not be truncated. A maximum of 25 results are supported, if more journals are found you will need to refine your search.
  Examples:
    search american journal of b
    search exact outlook
    search 1553-3468
EOL
    }
    elsif ( $string =~ /select/ ) {
        return << "EOL";
select result_number
  Selects a search result to work with.  After a select is done any "url", "coverage", "titles", etc. command will return data for that result.
  Examples:
    result 1

EOL
    }
    elsif ( $string =~ /more/ ) {
        return << "EOL";
more
   Displays text next 400 (or so) characters when the data returned was too long for the IM system.
   Examples:
      more
EOL
    }
    elsif ( $string =~ /current/ ) {
        return << "EOL";
current
Displays the currently selected journal
EOL
    }
    elsif ( $string =~ /results/ ) {
        return << "EOL";
results
  Displays the result list from the last search
EOL
    }
    elsif ( $string =~ /titles/ ) {
        return << "EOL";
titles [result_number]
   Displays a list of alternate titles for the selected journal
   Examples:
     titles
     titles 5
EOL
    }
    elsif ( $string =~ /issns/ ) {
        return << "EOL";
issns [result_number]
   Displays a list of ISSNs for the selected journal
   Examples:
     issns
     issns 2
EOL
    }
    elsif ( $string =~ /coverage/ ) {
        return << "EOL";
coverage [result_number]
   Displays a list of databases the journal can be found in and what the coverage periods for citations and full text are.
   Examples:
     coverage
     coverage 3
EOL
    }
    elsif ( $string =~ /urls/ ) {
        return << "EOL";
coverage [result_number]
   Displays a list of databases the journal can be found in and URLs to them. If you have picked a site, the system will only display links to databases you have access to and will link through your site's proxy server. If "open" is specified, only links to open access content will be returned.
   Examples:
     urls open
     urls 1
EOL
    }
    elsif ( $string =~ /full/ ) {
        return << "EOL";
full [result_number] [open]
   Displays a list of databases the journal can be found in, coverage periods, and URLs to them. If you have picked a site, the system will only display links to databases you have access to and will link through your site's proxy server. If "open" is specified, only links to open access content will be returned.
   Examples:
     full
     full open
     full 10
EOL
    }
    elsif ( $string =~ /site/ ) {
        return << "EOL";
site site_key
   Selects a current site. This is used to return only links to journals that you can access through your institution. The site_key is the NUC code for your site, which must be actively using CUFTS for this to work.
   Examples:
     site BVAS
     site ALU
EOL
    }
    elsif ( $string =~ /marc/ ) {
        return << "EOL";
marc [result_number]
   Returns a human readable dump of the MARC record for the journal. A subset of the journals in CUFTS have associated MARC data, so this will not be available for all journals.
   Examples:
     marc
     marc 3
EOL
    }
    elsif ( $string =~ /commands/ ) {
        return << "EOL";
search ( [exact] title | issn )
select result number
current
results 
titles [result_number]
issns [result_number]
coverage [result_number]
marc
more
urls [open]
full [open]
site site_key
EOL
    } else {
        return << "EOL";
This bot is used to search the CUFTS journals database for information on where journals are indexed, available in fulltext, and what the coverage periods are.
"help commands" will give a list of valid commands.
Example Usage:
  search outlook
  select 4
  coverage
  results
  site BVAS
  urls 2
EOL
    }
}



sub get_cufts_ft_coverage {
    my ($journal) = @_;

    my $ft_coverage;

    if (   defined( $journal->ft_start_date )
        || defined( $journal->ft_end_date ) )
    {
        $ft_coverage = $journal->ft_start_date;
        if (   defined( $journal->vol_ft_start )
            || defined( $journal->iss_ft_start ) )
        {
            $ft_coverage .= ' (';
            defined( $journal->vol_ft_start )
                and $ft_coverage .= 'v.' . $journal->vol_ft_start;
            if ( defined( $journal->iss_ft_start ) ) {
                defined( $journal->vol_ft_start )
                    and $ft_coverage .= ' ';
                $ft_coverage .= 'i.' . $journal->iss_ft_start;
            }
            $ft_coverage .= ')';
        }

        $ft_coverage .= ' - ';
        $ft_coverage .= $journal->ft_end_date;

        if (   defined( $journal->vol_ft_end )
            || defined( $journal->iss_ft_end ) )
        {
            $ft_coverage .= ' (';
            defined( $journal->vol_ft_end )
                and $ft_coverage .= 'v.' . $journal->vol_ft_end;
            if ( defined( $journal->iss_ft_end ) ) {
                defined( $journal->vol_ft_end )
                    and $ft_coverage .= ' ';
                $ft_coverage .= 'i.' . $journal->iss_ft_end;
            }
            $ft_coverage .= ')';
        }
    }

    return $ft_coverage;
}

sub get_cufts_cit_coverage {
    my ($journal) = @_;

    my $cit_coverage;

    if (   defined( $journal->cit_start_date )
        || defined( $journal->cit_end_date ) )
    {
        $cit_coverage = $journal->cit_start_date;
        if (   defined( $journal->vol_cit_start )
            || defined( $journal->iss_cit_start ) )
        {
            $cit_coverage .= ' (';
            defined( $journal->vol_cit_start )
                and $cit_coverage .= 'v.' . $journal->vol_cit_start;
            if ( defined( $journal->iss_cit_start ) ) {
                defined( $journal->vol_cit_start )
                    and $cit_coverage .= ' ';
                $cit_coverage .= 'i.' . $journal->iss_cit_start;
            }
            $cit_coverage .= ')';

        }

        $cit_coverage .= ' - ';
        $cit_coverage .= $journal->cit_end_date;

        if (   defined( $journal->vol_cit_end )
            || defined( $journal->iss_cit_end ) )
        {
            $cit_coverage .= ' (';
            defined( $journal->vol_cit_end )
                and $cit_coverage .= 'v.' . $journal->vol_cit_end;
            if ( defined( $journal->iss_cit_end ) ) {
                defined( $journal->vol_cit_end )
                    and $cit_coverage .= ' ';
                $cit_coverage .= 'i.' . $journal->iss_cit_end;
            }
            $cit_coverage .= ')';
        }
    }

    return $cit_coverage;
}

sub get_url {
    my ( $journal, $sender, $open ) = @_;

    my $out;

    my $site = $cache->{$sender}->{site};
    if ( !$open && !defined($site) && not_empty_string($journal->journal_url) ) {
        return "journal: " . $journal->journal_url;
    }
    
    if ( !defined($site) ) {
       $site = CUFTS::DB::Sites->search('key' => 'OPEN')->first;
       if ( !defined($site) ) {
            return undef;
        }
    }
    
    my @links;
    
    my $local_resource = CUFTS::DB::LocalResources->search( 'site' => $site->id, 'resource' => $journal->resource->id, 'active' => 't' )->first;
    return undef if !defined($local_resource);

	CUFTS::Resolve->overlay_global_resource_data($local_resource);
	return undef if !defined($local_resource->module);

	my $module = CUFTS::Resolve::__module_name($local_resource->module);
	CUFTS::Resolve->__require($module);
    
    my $local_journal = CUFTS::DB::LocalJournals->search( 'journal' => $journal->id, 'resource' => $local_resource->id )->first;
    return undef if !defined($local_journal);

    $local_journal = $module->overlay_global_title_data($local_journal);

	my $request = new CUFTS::Request;
	$request->title($local_journal->title);
	$request->genre('journal');
	$request->pid({});

	my $results;
	
	if ( $module->can_getJournal($request) ) {

		$results = $module->build_linkJournal([$local_journal], $local_resource, $site, $request);
		foreach my $result (@$results) {
			$module->prepend_proxy($result, $local_resource, $site, $request);
			push @links, "journal: " . $result->url;
		}

	}

	if ( !scalar(@$results) && $module->can_getDatabase($request) ) {

		$results = $module->build_linkJournal([$local_journal], $local_resource, $site, $request);
		foreach my $result (@$results) {
			$module->prepend_proxy($result, $local_resource, $site, $request);
			push @links, "database: " . $result->url;
		}

	}
		
    if ( scalar(@links) ) {
        $out .= join "\n", @links;
    }
    
    return $out;
}

sub _dump_cache {
    my ( $string, $sender ) = @_;
    
    warn(Dumper($cache));
    
    return "Dumped.\n";
}

