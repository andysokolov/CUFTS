#!/usr/local/bin/perl

##
## CUFTS installation script.
##
## This file is part of CUFTS.
##
## CUFTS is free software; you can redistribute it and/or modify it under
## the terms of the GNU General Public License as published by the Free
## Software Foundation; either version 2 of the License, or (at your option)
## any later version.
## 
## CUFTS is distributed in the hope that it will be useful, but WITHOUT ANY
## WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
## FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
## details.
##
## You should have received a copy of the GNU General Public License along
## with CUFTS; if not, write to the Free Software Foundation, Inc., 59
## Temple Place, Suite 330, Boston, MA 02111-1307 USA

use lib qw(lib);

## This script could use some testing and cleanup.

use strict;

my $config = {};
my $no_DBI = 0;
my $no_psql = 0;
my $skip_db = 0;

my @write_to_directories = qw(
    uploads
    logs
    data
    CJDB/root/sites
    CRDB/root/sites
    Resolver/root/sites
    MaintTool/root/static/erm_files
);

my @modules = qw(
    Biblio::COUNTER
    Business::ISSN
    Catalyst
    Catalyst::Plugin::FillInForm
    Catalyst::Plugin::FormValidator
    Catalyst::Plugin::Session::Store::FastMmap
    Catalyst::Plugin::Session::State::Cookie
    Catalyst::View::Download::CSV
    Catalyst::View::JSON
    Catalyst::View::TT
    Chart::OFC
    Class::Accessor
    Class::DBI
    Class::DBI::AbstractSearch
    Class::DBI::Plugin::FastDelete
    Class::DBI::Plugin::CountSearch
    Class::DBI::Plugin::FastDelete
    Class::DBI::Plugin::Type
    Class::DBI::Sweet
    Date::Calc
    DateTime
    DateTime::Format::ISO8601
    Exception::Class
    Exception::Class::DBI
    Getopt::Long
    HTML::Entities
    HTML::FillInForm
    HTML::Strip
    JSON::XS
    Log::Log4perl
    List::Compare
    List::MoreUtils
    LWP::UserAgent
    MARC::Charset
    MARC::Record
    MIME::Lite
    Net::LDAPS
    Net::SMTP
    Perl6::Export::Attrs
    SQL::Abstract
    String::Approx
    String::Util
    Template
    Template::Plugin::JSON
    Term::ReadLine
    Text::CSV
    Unicode::String
    URI::Escape
    URI::OpenURL
    XML::DOM
    XML::Parser::Lite::Tree
    XML::RAI
);

my @optional_modules = qw(Apache::DBI);

if (grep {$_ eq '-m'} @ARGV) {
	check_modules(@modules);
	optional_modules(@optional_modules);
	print "\n\n";

	exit;
}


##
## CUFTS installation script. Sets up ownership, etc.
##

use Term::ReadLine;
my $term = new Term::ReadLine 'CUFTS Installation';

##
##  Introduction
##

show_introduction();

##
## Configuration tests... is DBI and PostgreSQL installed?
##

print "\nChecking for necessary tools.\n";

$no_DBI = !check_DBI();

if ($no_DBI) {
	print "** DBI or DBD::Pg not found. You can continue with installation,\nbut testing for an existing database will not be possible. It is\nrecommended that you abort the installation here and install DBI\nwith DBD::Pg before continuing.\nContinue?\n";
	my $input = $term->readline('[y/N]: ');
	exit unless $input =~ /^\s*y/i;
}


$no_psql = !check_psql();
if ($no_psql) {
	print "** 'psql' or 'createdb' was not found in the current path.\nThis installation script uses the PostgreSQL command\nline tools to set up the database. You can continue without them and install the database yourself\nlater, but it is recommended that you abort the installation here and install PostgreSQL or fix the path.\nContinue?\n";
	my $input = $term->readline('[y/N]: ');
	exit unless $input =~ /^\s*y/i;
}
	
print "Finished preliminary checks.\n\n";

##
## Initial directory setup
##

# Get base directory - ignore whatever is in the config file and use the current working dir
# as a start.
# If it's not the current directory, copy all files there.

my $copy_files = 0;

chomp(my $cwd = `pwd`);

verify_cwd($cwd);

print "Current working directory is: $cwd\n";
print "What directory will CUFTS be run from (CUFTS base directory) ?\n";
my $input = $term->readline("[$cwd]: ");

my $base_dir;
if (defined($input) && $input =~ /\S/) {
	$base_dir = $input;
	$copy_files = 1;
} else {
	$base_dir = $cwd;
}

print "Installing CUFTS in: $base_dir\n";

$config->{'CUFTS_BASE_DIR'} = $base_dir;

if ($copy_files) {
    print "Do you want to copy the CUFTS tree to $base_dir?\n";
	my $input = $term->readline('[Y/n]: ');
	unless ($input =~ /^\s*n/i) {
		copy_files($base_dir);
	}
}

##
## Load config file and ask for changes. Set up db name, db user, db password, and SMTP info
##

chdir $base_dir;
get_existing_config($config);

print "\nPlease answer the following setup questions. Entering nothing\nwill maintain the current settings...\n\n";
get_new_config($config);  		# Overwrites $config with entered options

##
## Write config files changes
##

print "Do you want to update the configuration file with the new settings?\n";
$input = $term->readline('[Y/n]: ');
unless ($input =~ /^\s*n/i) {
	write_config_file("lib/CUFTS/BasicConfig.pm", $config);
}

##
## Set up directory permissions
##

print "CUFTS needs the web server to be able to write to several directories for\nthings such as logs and uploaded title lists. If you have root access you\ncan set these directories to be owned by the web server owner. If not,\nthey should be set world writable.\n\n";
if ($> == 0) {
	print "It appears you are running as root. Would you like to change ownership\nof the directories?\n";
	my $input = $term->readline("[Y/n]: ");
	unless ($input =~ /\s*n/i) {
GET_USERNAME:
		print "User which the web server runs as?\n";
		my $input = $term->readline("[nobody]: ");
		$input = 'nobody' unless defined($input) && $input ne '';
		my $uid = scalar(getpwnam $input);
		if (!defined($uid)) {
			print "* That user was not found in the password file. Enter another user or\nCtrl-C to exit.\n";
			goto GET_USERNAME;
		}		

		set_owner($uid, -1, @write_to_directories);
	}
} else {
	print "It appears you are NOT running as root. World writable directories are\nanother option, however world writable directories could be a security\nconcern, depending on your server configuration.\n\nIf you are not sure about this step, skip this and ask your server\nadministrator about your options.\n\nWould you like to set the directories to world writable?\n";
	my $input = $term->readline("[Y/n]: ");
	unless ($input =~ /\s*n/i) {
		set_modes(0777, @write_to_directories);
	}
}

##
## Web tree
##

setup_web_apps($config);

##
## Ask about database configuration
##

if ($no_psql) {
	print "The database cannot be installed due to missing PostgreSQL\nbinaries. You will have to install the database by hand or\nfix your PostgreSQL installation and re-run this script.\n";
} else {
	print "Directory installation complete. Would you like to install the database?\n";
	my $input = $term->readline("[Y/n]: ");
	$input =~ /^\s*n/i and
		$skip_db = 1;

	##
	## Check for existing database
	##

	unless ($skip_db) {
		my $db_exists = 0;

		if ($no_DBI) {
			print "\nDBI and/or DBD::Pg is not available so an existing database\ncannot be checked. If you continue to install the database\nyou risk corrupting an existing CUFTS database you may have\ninstalled.\n\nReally continue?\n";
			my $input = $term->readline("[y/N]: ");
			$input =~ /^\s*y/ or
				$db_exists = 1;
		} else {
			if (db_exists($config)) {
				print "A database already exists with the name '$config->{'CUFTS_DB'}'. Do you want to drop\nthis database before continuing with installation?\nIf you do not drop the database, installation will continue without database modifications.\n\n** WARNING: dropping the database will lose any content currently stored! **\n\nDrop database?\n";
				my $input = $term->readline("[y/N]: ");
		
				if ($input =~ /^\s*y/i) {
					drop_databases($config);
				} else {
					$db_exists = 1;
				}
			}
		}

		##
		## Create database
		##

		unless ($db_exists) {
			print "Creating CUFTS database. If you have entered a password above, you will be asked to enter it again.\n";
			my $pw = defined($config->{'CUFTS_PASSWORD'}) && $config->{'CUFTS_PASSWORD'} ne '' ? '--password' : '';
			my $result = `createdb -e --lc-collate=C --encoding=SQL_ASCII --template=template0 --username=$config->{'CUFTS_USER'} $pw $config->{'CUFTS_DB'}`;
			if ($result !~ /CREATE\sDATABASE/) {
				die("Error creating database: $result\n\nIf the above error is something like FATAL: IDENT auth failed,\nyou are trying to create the database as a user other than\nthe one you are currently logged in as, and PostgreSQL is set\nto use 'ident' authentication. See the pg_hba.conf PostgreSQL config file.\n");
			}

			print "Database created.\n\n";

			##
			## Create tables
			##
		
			print "Creating CUFTS database tables and seeding database. Ignore the NOTICE: lines.\nYou may be asked for the password again.\n";
			$result = `cat sql/CUFTS/*.sql sql/CUFTS/views/*.sql sql/CJDB/*.sql sql/CUFTS/init/*.sql | psql -q --username=$config->{'CUFTS_USER'} $pw $config->{'CUFTS_DB'}`;
			if ($result =~ /ERROR/) {
				die("Error creating/seeding database: $result");
			}
			print "\n\nDone with basic database setup.\n";

			print "\nInitialize the database with example global resources and journal lists?\n";
			my $input = $term->readline('[Y/n]: ');
			unless ($input =~ /^\s*n/i) {
				print "Loading global databases... this may take a while...\n";
				`util/import_global_sync.pl sql/CUFTS/init/examples.tgz`;
				print "done!\n";
                print "Building first journals auth table...\n";
				`util/build_journals_auth.pl`;
				print "done!\n";
			}

		}
	}
}

check_modules(@modules);
optional_modules(@optional_modules);

print "\n\nDONE!\n\n";


##
## show_introduction - Welcome to CUFTS, show information, ask to continue
##

sub show_introduction {
	print "Configuring CUFTS\n";
	print "=================\n";

	##
	## Notes about configuration
	##

	my $continue = show_notes();
	exit unless $continue;

}

##
## check_DBI - Checks whether DBI and DBD::Pg are installed
##

sub check_DBI {
	print "DBI installed... ";
	my $dbi = 0;
	my $dbd = 0;
	
	eval { require DBI; };
	if ($@) {
		print "no.\n";
	} else {
		print "yes.\n";
		$dbi = 1;
	}

	print "DBD::Pg installed... ";
	eval { require DBD::Pg; };
	if ($@) {
		print "no.\n";
	} else {
		print "yes.\n";
		$dbd = 1;
	}

	return $dbi && $dbd;
}


##
## check_psql - Checks whether PostgreSQL tools are available
##

sub check_psql {
	my $psql = 0;

	print "PostgreSQL tools available... ";

	my $psql_check = `psql --help`;
	if ($psql_check =~ /PostgreSQL/) {
		$psql = 1;
	} 	

	$psql_check = `createdb --help`;
	if ($psql_check =~ /PostgreSQL/) {
		$psql = 1;
	} 	

	print $psql ? "yes.\n" : "no.\n";

	return $psql;
}




##
## verify_cwd - Checks for various CUFTS directories and files to be reasonably sure
##              the script is running from the correct directory.
##

sub verify_cwd {
	my $cwd = shift;
	
	my @files = qw(
		util/install.pl
		lib/CUFTS/Resources.pm
		lib/CUFTS/Resolve.pm
		lib/CUFTS/DB/DBI.pm
		sql/CUFTS/services.sql
        Resolver/lib/CUFTS/Resolver.pm
        CJDB/lib/CUFTS/CJDB.pm
        MaintTool/lib/CUFTS/MaintTool.pm
	);

	foreach my $file (@files) {
		-e "$cwd/$file" or
			die("*** Installation script run from the wrong directory, or this is an incomplete CUFTS package.\n*** Could not locate file '$file'.\n");
	}
}


##
## copy_files - Copies the installation tree to its installation destination
##

sub copy_files {
	my $destination = shift;

	unless (-d $destination) {
		print "Creating directory $destination... ";
		mkdir $destination;
		print "done.\n";
	}
	print "Copying files to $destination... ";
	`cp -r * $destination`;
	print "done.\n";
}

##
## write_config_file - Creates a new BasicConfig file based on a template. This 
## will overwrite the existing config file, but a backup copy is made.
##

sub write_config_file {
	my ($file, $config) = @_;
	
	-e $file and
		`cp '$file' ${file}.backup`;

	open CONFIG, ">$file"  or
		die "Unable to open configuration file for writing: $!";
	
	print CONFIG <<EOF;
## CUFTS::BasicConfig
##
## Copyright Todd Holbrook - Simon Fraser University (2003)
##
## This file is normally written by the install script, but can be modified by
## hand if necessary later.
##
package CUFTS::Config;

use strict;

use vars qw(
	\$CUFTS_BASE_DIR

	\$CUFTS_DB
	\$CUFTS_USER
	\$CUFTS_PASSWORD

	\$CUFTS_SMTP_HOST
	\$CUFTS_MAIL_FROM
);

\$CUFTS_BASE_DIR = '$config->{'CUFTS_BASE_DIR'}';

\$CUFTS_DB = '$config->{'CUFTS_DB'}';
\$CUFTS_USER = '$config->{'CUFTS_USER'}';
\$CUFTS_PASSWORD = '$config->{'CUFTS_PASSWORD'}';

\$CUFTS_SMTP_HOST = '$config->{'CUFTS_SMTP_HOST'}';
\$CUFTS_MAIL_FROM = '$config->{'CUFTS_MAIL_FROM'}';

1;

EOF

	close CONFIG;

}
	
sub get_existing_config {
	my ($config) = @_;
	
	eval { require CUFTS::BasicConfig };
	unless ($@) {
		$config->{'CUFTS_DB'}         = $CUFTS::Config::CUFTS_DB || 'CUFTS';
		$config->{'CUFTS_USER'}       = $CUFTS::Config::CUFTS_USER || scalar(getpwent);
		$config->{'CUFTS_PASSWORD'}   = $CUFTS::Config::CUFTS_PASSWORD;
		$config->{'CUFTS_SMTP_HOST'}  = $CUFTS::Config::CUFTS_SMTP_HOST;
		$config->{'CUFTS_MAIL_FROM'}  = $CUFTS::Config::CUFTS_MAIL_FROM;
	}
}

sub get_new_config {
	my ($config) = @_;
	
	print "CUFTS Database name: $config->{'CUFTS_DB'}\n";
	my $input_cufts_db = $term->readline("[$config->{'CUFTS_DB'}]: ");
	defined($input_cufts_db) && $input_cufts_db ne '' and
		$config->{'CUFTS_DB'} = $input_cufts_db; 

	print "CUFTS Database user: $config->{'CUFTS_USER'}\n";
	if ($config->{'CUFTS_USER'} eq 'root') {
		print "** You should probably not use root as the database owner. **\n";
	}
	my $input_cufts_user = $term->readline("[$config->{'CUFTS_USER'}]: ");
	defined($input_cufts_user) && $input_cufts_user ne '' and
		$config->{'CUFTS_USER'} = $input_cufts_user;

	print "CUFTS Database password: $config->{'CUFTS_PASSWORD'}\n";
	my $input_cufts_password = $term->readline("[$config->{'CUFTS_PASSWORD'}]: ");
	defined($input_cufts_password) && $input_cufts_password ne '' and
		$config->{'CUFTS_PASSWORD'} = $input_cufts_password;

	print "Mail host for outgoing CUFTS mail: $config->{'CUFTS_SMTP_HOST'}\n";
	my $input_cufts_smtp_host = $term->readline("[$config->{'CUFTS_SMTP_HOST'}]: ");
	defined($input_cufts_smtp_host) && $input_cufts_smtp_host ne '' and
		$config->{'CUFTS_SMTP_HOST'} = $input_cufts_smtp_host;

	print "Mail should be from: $config->{'CUFTS_MAIL_FROM'}\n";
	my $input_cufts_mail_from = $term->readline("[$config->{'CUFTS_MAIL_FROM'}]: ");
	defined($input_cufts_mail_from) && $input_cufts_mail_from ne '' and
		$config->{'CUFTS_MAIL_FROM'} = $input_cufts_mail_from;

	print "\n";
}

	
sub db_exists {
	my ($config) = @_;

	print "Trying DBI connection...";
		
	my $dbh = DBI->connect("dbi:Pg:dbname=$config->{'CUFTS_DB'}", $config->{'CUFTS_USER'}, $config->{'CUFTS_PASSWORD'}, {'PrintError' => 0});
	if (defined($dbh)) {
		print " found.\n";
		return 1;
	} else {
		print " not found.\n";
		if ($DBI::errstr =~ /database\s+".*?"\s+does\s+not\s+exist/i) {
			return 0;
		}

		if ($DBI::errstr =~ /user\s+".*?"\s+does\s+not\s+exist/i) {
			die("The user you entered does not exist in the database. Please add the user before attempting to install,\nor skip the automated database installation.\n");
		}
		
		die("Unexpected DBI error connecting to database: $DBI::errstr\n");
	}
}	


sub drop_databases {
	my ($config) = @_;

	print "Dropping CUFTS database. If you have entered a password above, you will be asked to enter it again.\n";
	my $pw = defined($config->{'CUFTS_PASSWORD'}) && $config->{'CUFTS_PASSWORD'} ne '' ? '--password' : '';
	my $result = `dropdb -e --username=$config->{'CUFTS_USER'} $pw $config->{'CUFTS_DB'}`;
	if ($result !~ /DROP\sDATABASE/) {
		die("Error dropping database: $result");
	}

	return 1;
}

sub show_notes {
	print "First, some comments about installation...\n\n";
	print "* The CUFTS installation needs access to DBI under Perl and the PostgreSQL\ncommandline tools to install the database. You can continue without these,\nbut you will have to set up the database by hand.\n\n";
	print "* CUFTS needs to write to a few directories as the web server for session\ntracking, logs, etc. If you are not running as root, you will have to\nchown these directories manually, or allow the installation script to\nmake them world writable.\n\n";
	print "If you need to set up PostgreSQL or DBI, or switch to root, you can exit now.\n";
	print "Continue with installation?\n";
	
	my $input = $term->readline("[Y/n]: ");
	if ($input =~ /^\s*n/i) {
		return 0;
	} else {
		return 1;
	}
}

sub set_modes {
	my ($mode, @directories) = @_;

	foreach my $dir (@directories) {
		print "Setting '$dir'... ";
		if (chmod $mode, $dir) {
			print "ok.\n";
		} else {
			print "failed.\n";
		}
	}
	print "\n";
}

sub set_owner {
	my ($owner, $group, @directories) = @_;

	foreach my $dir (@directories) {
		print "Setting '$dir'... ";
		if (chown $owner, $group, $dir) {
			print "ok.\n";
		} else {
			print "failed.\n";
		}
	}
	print "\n";	
}


sub setup_web_apps {
	my ($config) = @_;
	
	print "\nDo you want to configure the web applications?\n";
	return if $term->readline('[Y/n]: ') =~ /^\s*n/i;
	
	create_apache_config_block($config);
}


sub create_apache_config_block {
	my ($config, $directory) = @_;
	
	print "\nDo you have access to update your web server's config file?\n";
	my $input = $term->readline('[Y/n]: ');
	
	if ($input =~ /^\s*n/i) {
		create_apache_config_no($config, $directory);
	} else {
		print "\nIs your web server running Apache 1.3.x w/ mod_perl?\n";
		my $input = $term->readline('[Y/n]: ');
		if ($input =~ /^\s*n/i) {
			print "\nIs your web server running Apache 2.0.x w/ mod_perl 2.x?\n";
			my $input = $term->readline('[Y/n]: ');
			if ($input =~ /^\s*n/i) {
				create_apache_config_no($config, $directory);
			} else {
				create_apache_config_modperl2($config, $directory);
			}
		} else {
			create_apache_config_modperl1($config, $directory);
		}
	}
}
			

sub create_apache_config_modperl2 {
	my ($config, $directory) = @_;
	
	open CONF, ">$config->{'CUFTS_BASE_DIR'}/util/httpd.conf" or
		die("Unable to open util/httpd.conf file for writing: $!");
		
	print CONF <<EOF;

    PerlRequire $config->{'CUFTS_BASE_DIR'}/util/startup.pl
    PerlSwitches -I$config->{'CUFTS_BASE_DIR'}/lib -I$config->{'CUFTS_BASE_DIR'}/MaintTool/lib -I$config->{'CUFTS_BASE_DIR'}/Resolver/lib -I$config->{'CUFTS_BASE_DIR'}/CJDB/lib
    PerlLoadModule CUFTS::MaintTool
    PerlLoadModule CUFTS::Resolver
    PerlLoadModule CUFTS::CJDB
#    PerlTransHandler Apache2::Const::OK

    <Location /CUFTS/MaintTool>
            SetHandler modperl
            PerlResponseHandler CUFTS::MaintTool
    </Location>


    <Location /CUFTS/Resolver>
            SetHandler modperl
            PerlResponseHandler CUFTS::Resolver
    </Location>

    <Location /CJDB>
            SetHandler modperl
            PerlResponseHandler CUFTS::CJDB
    </Location>
EOF

	close CONF;

	print "\nhttpd.conf file created. Copy the following line into your\nApache config file:\n\nInclude $config->{'CUFTS_BASE_DIR'}/util/httpd.conf\n\nIf you do NOT have Apache::DBI installed, you should comment out\nthe 'use Apache::DBI' line from $config->{'CUFTS_BASE_DIR'}/util/startup.pl\n\n";
}

sub create_apache_config_modperl1 {
	my ($config, $directory) = @_;
	
	open CONF, ">$config->{'CUFTS_BASE_DIR'}/util/httpd.conf" or
		die("Unable to open util/httpd.conf file for writing: $!");
		
	print CONF <<EOF;

    PerlRequire $config->{'CUFTS_BASE_DIR'}/util/startup.pl
    <Perl>
            use lib qw[$config->{'CUFTS_BASE_DIR'}/lib $config->{'CUFTS_BASE_DIR'}/MaintTool/lib $config->{'CUFTS_BASE_DIR'}/CJDB/lib $config->{'CUFTS_BASE_DIR'}/Resolver/lib];
    </Perl>
    <Location /MaintTool>
            PerlModule CUFTS::MaintTool
            SetHandler perl-script
            PerlHandler CUFTS::MaintTool
    </Location>

    <Location /Resolver>
            PerlModule CUFTS::Resolver
            SetHandler perl-script
            PerlHandler CUFTS::Resolver
    </Location>

    <Location /CJDB>
            PerlModule CUFTS::CJDB
            SetHandler perl-script
            PerlHandler CUFTS::CJDB
    </Location>

EOF

	close CONF;

	print "\nhttpd.conf file created. Copy the following line into your\nApache config file:\n\nInclude $config->{'CUFTS_BASE_DIR'}/util/httpd.conf\n\nIf you do NOT have Apache::DBI installed, you should comment out\nthe 'use Apache::DBI' line from $config->{'CUFTS_BASE_DIR'}/util/startup.pl\n\n";
}
	
		
sub create_apache_config_no {
	my ($config, $directory) = @_;

	print "\nIf you do not have access to the Apache config file,\nyou will have to run the web applications as CGIs.  This setup\nis NOT recommended and as such no support is included here.\nInformation about running Catalyst (which CUFTS uses as a web\nframework) through CGI can be found at the Catalyst web site.\n";
}	
	


##
## Check for all the modules CUFTS uses.
##

sub check_modules {
	my (@modules) = @_;

	print "\nCUFTS needs a number of Perl modules to work...\n";

	my $missing = 0;
	foreach my $module (sort @modules) {
		print "Checking for module $module... ";
		if (check_module($module)) {
			print "found\n";
		} else {
			print "not found\n";
			$missing++;
		}
	}
	if ($missing == 0) {
		print "Great, you seem to have everything necessary!\n";
	} else {
		print "You're missing some modules. Please use CPAN to install them.\nYou can use $0 -m to check for the modules again.\n";
	}
}

sub optional_modules {
	my (@optional_modules) = @_;

	print "\nIf you plan on running under Apache with mod_perl, these modules\nwill be useful as well...\n";

	my $missing = 0;
	foreach my $module (sort @optional_modules) {
		print "Checking for module $module... ";
		if (check_module($module)) {
			print "found\n";
		} else {
			print "not found\n";
			$missing++;
		}
	}
}
	
	

sub check_module {
	my ($module) = @_;

	$module =~ s#::#/#g;
	$module .= '.pm';
	
	eval { require $module };
	return $@ =~ /Can't\slocate/ ? 0 : 1;
}


1;


__END__

TODO:

- change permissions stuff so that the writable directories could be chmod g+w
  and chgrp to the web server