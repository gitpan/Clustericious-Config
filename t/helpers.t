#!/usr/bin/env perl

use Test::More;
use Clustericious::Config;
use Test::Differences;
use strict;

my $c = Clustericious::Config->new(\(my $a = <<'EOT'));
---
first  : one
second : two
third  : <%= conf->first %>
fourth : <%= conf->third %>
deep :
  under : water
h20 : <%= conf->deep->under %>
double : [ <%= conf->first %>, <%= conf->second %> ]
some :
  place :
     deeply :
        nested : [ <%= conf->first %> ]
EOT

is $c->first, 'one', 'set yaml key';
is $c->second, 'two', 'set yaml key';
is $c->third, 'one', 'used conf helper';
is $c->fourth, 'one', 'used conf helper again';
is $c->h20, 'water', 'nested conf';
my $double = $c->double;
eq_or_diff $double, [qw/one two/], 'double';
my $deep = $c->some->place->deeply->nested;
eq_or_diff $deep, ['one'], 'deep data structure';

done_testing();

1;

