package Clustericious::Config::Password;

use Data::Dumper;

use strict;
use warnings;

our $VERSION = '0.14';
our $Stashed;

sub sentinel {
    return "__XXX_placeholder_ceaa5b9c080d69ccdaef9f81bf792341__";
}

sub get {
    my $self = shift;
    require Term::Prompt;
    $Stashed ||= Term::Prompt::prompt('p', 'Password:', '', '');
    $Stashed;
}

sub is_sentinel {
    my $class = shift;
    my $val = shift;
    return (defined($val) && $val eq $class->sentinel);
}

1;

