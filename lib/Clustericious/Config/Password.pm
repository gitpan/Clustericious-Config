package Clustericious::Config::Password;

use Data::Dumper;

use strict;
use warnings;

=head1 NAME

Clustericious::Config::Password - password routines for Clustericious::Config

=head1 DESCRIPTION

This module provides the machiery for handling passwords used by
L<Clustericious::Config> and L<Clustericious::Config::Plugin>.

=head1 SEE ALSO

L<Clustericious::Config>, L<Clustericious>

=cut

our $VERSION = '0.16';
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

