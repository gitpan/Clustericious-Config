package Clustericious::Config::Plugin::Conf;

use warnings;
use strict;

use overload '""' => \&freeze;

our $VERSION = '0.14';

my $magic_num = 'xxx_confvar_';

sub new {
    bless { _want => [] }, shift;
}

sub freeze {
    my $c = shift;
    return $magic_num.join '.', @{ $c->{_want} }
}

sub unfreeze {
    my $class = shift;
    my $str = shift;
    return undef unless defined($str);
    return unless $str =~ s/^$magic_num//;
    my $new = $class->new();
    $new->{_want} = [ reverse split /\./, $str ];
    return $new;
}

sub AUTOLOAD {
    our $AUTOLOAD;
    my $self = shift;
    my $want = $AUTOLOAD;
    $want =~ s/.*:://g;
    push @{ $self->{_want} },$want;
    return $self;
}

sub eval {
    my $self = shift;
    my $config = shift;
    my $got = $config;
    while (my $want = pop @{ $self->{_want} }) {
        while (!exists($got->{$want}) && $got->{_parent}) {
            $got = $got->{_parent};
        }
        $got = $got->$want;
    }
    return $got;
}

sub DESTROY {

}

1;

