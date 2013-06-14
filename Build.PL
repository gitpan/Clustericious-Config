#!/usr/bin/env perl

use strict;
use warnings;
use v5.10;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Clustericious-Config',
    license             => 'perl',
    dist_author         => q{Brian Duggan <brian.duggan@nasa.gov>},
    dist_version_from   => 'lib/Clustericious/Config.pm',
    dist_abstract       => 'Configuration for clustericious clients or servers',
    configure_requires => { 'Module::Build' => 0.36 },
    build_requires => {
        'Module::Build'        => '0.36',
        'Test::More'           => 0,
        'Mojolicious'          => '1.01',
        'JSON::XS'             => 0,
        'YAML::XS'             => 0,
        'Hash::Merge'          => 0,
        'Term::Prompt'         => 0,
        'Log::Log4perl'        => 0,
        'File::HomeDir'        => 0,
      },
    add_to_cleanup      => [ 'Clustericious-Config-*' ],
    meta_merge => {
        no_index => { directory => [ 'share', 'util' ], },
        resources => {
            bugtracker => 'https://github.com/plicease/Clustericious-Config/issues',
            homepage   => "http://perl.wdlabs.com/Clustericious-Config",
            repository => 'git://github.com/plicease/Clustericious-Config.git',
        }
    }
);

$builder->create_build_script();

1;
