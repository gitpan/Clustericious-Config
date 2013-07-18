
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "File::HomeDir::Test" => 0,
    "File::Temp" => 0,
    "IO::File" => 0,
    "Module::Build" => "0.3601",
    "Test::More" => 0
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "configuration files for Clustericious nodes.",
  "dist_author" => [
    "Graham Ollis <plicease\@cpan.org>"
  ],
  "dist_name" => "Clustericious-Config",
  "dist_version" => "0.25",
  "license" => "perl",
  "module_name" => "Clustericious::Config",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Carp" => 0,
    "Cwd" => 0,
    "Data::Dumper" => 0,
    "Exporter" => 0,
    "File::HomeDir" => 0,
    "File::Path" => 0,
    "Hash::Merge" => 0,
    "JSON::XS" => 0,
    "List::Util" => 0,
    "Log::Log4perl" => 0,
    "Module::Build" => 0,
    "Mojo::Base" => 0,
    "Mojo::Loader" => 0,
    "Mojo::Template" => 0,
    "Path::Class::Dir" => 0,
    "Path::Class::File" => 0,
    "Storable" => 0,
    "Sys::Hostname" => 0,
    "Term::Prompt" => 0,
    "Test::Builder::Module" => 0,
    "YAML::XS" => 0,
    "base" => 0,
    "perl" => "v5.10.0"
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
