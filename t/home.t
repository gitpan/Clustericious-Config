use strict;
use warnings;
use Test::Clustericious::Config;
use Clustericious::Config;
use Test::More tests => 3;
use File::Temp qw( tempdir );

do {
  
  my $dir = tempdir( CLEANUP => 1);
  my $users_home = sub {
    $_[1] eq 'foo' ? $dir : '';
  };

  no warnings 'redefine';
  *File::HomeDir::Test::users_home = $users_home;
};

create_config_ok 'Foo', <<EOF;
---
test: <%= home %>
bar: <%= home 'foo' %>
EOF

my $config = Clustericious::Config->new('Foo');

my $dir = eval { $config->test };
ok $dir && -d $dir, "home is $dir and is a dir";

my $dir2 = eval { $config->bar };
ok $dir2 && -d $dir2, "home 'foo' is $dir2 and is a dir";
