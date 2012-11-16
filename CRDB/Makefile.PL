use inc::Module::Install;

name 'CUFTS-CRDB';
all_from 'lib/CUFTS/CRDB.pm';

requires 'Catalyst' => '5.7007';
requires 'Catalyst::Plugin::ConfigLoader';
requires 'Catalyst::Plugin::Static::Simple';
requires 'Catalyst::Action::RenderView';
requires 'YAML'; # This should reflect the config file format you've chosen
                 # See Catalyst::Plugin::ConfigLoader for supported formats
catalyst;

install_script glob('script/*.pl');
auto_install;
WriteAll;
