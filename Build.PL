#!/usr/bin/env perl

use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Clustericious-Config',
    license             => 'perl',
    dist_author         => q{Brian Duggan <brian.duggan@nasa.gov>},
    dist_version_from   => 'lib/Clustericious/Config.pm',
    dist_abstract       => 'Configuration for clustericious clients or servers',
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
        'Data::Rmap'           => 0,
        'File::HomeDir'        => 0,
      },
    add_to_cleanup      => [ 'Clustericious-Config-*' ],
    meta_add => { no_index => { directory => [ 'share', 'util' ], } },
);

$builder->create_build_script();

1;
