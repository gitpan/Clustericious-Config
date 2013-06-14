=head1 NAME

Clustericious::Config::Plugin - Plugins for clustericious config files.

=head1 SYNOPSIS

 ---
 % extend_config 'SomeOtherConfig';

=head1 DESCRIPTION

This module provides the functions available in all configuration files
using L<Clustericious::Config>.

=head1 FUNCTIONS

=cut

package Clustericious::Config::Plugin;

use Hash::Merge qw/merge/;
use Data::Dumper;
use strict;
use warnings;
use base qw( Exporter );

our $VERSION = '0.17';
our @mergeStack;
our @EXPORT = qw( extends_config get_password conf );

=head2 extends_config

Extend the config using another config file.

=cut

sub extends_config {
    my $filename = shift;
    my @args = @_;
    push @mergeStack, Clustericious::Config->new($filename, \@args);
    return '';
}

#
#
# do_merges:
#
# Called after reading all config files, to process extends_config
# directives.
#
sub do_merges {
    my $class = shift;
    my $conf_data = shift; # Last one; Has highest precedence.

    return $conf_data unless @mergeStack;

    # Nested extends_config's form a tree which we traverse depth first.
    Hash::Merge::set_behavior( 'RIGHT_PRECEDENT' );
    my %so_far = %{ shift @mergeStack };
    while (my $c = shift @mergeStack) {
        my %h = %$c;
        %so_far = %{ merge( \%so_far, \%h ) };
    }
    %$conf_data = %{ merge( \%so_far, $conf_data ) };
}

=head2 get_password

Prompt for a password, if it is needed.

=cut

sub get_password {
    return Clustericious::Config::Password->sentinel;
}

=head1 SEE ALSO

L<Clustericious::Config>, L<Clustericious>

=cut

1;
