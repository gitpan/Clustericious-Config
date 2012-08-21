=head1 NAME

Clustericious::Config - configuration files for Clustericious nodes.

=head1 SYNOPSIS

 $ cat > ~/etc/MyApp.conf
 ---
 % extends_config 'global';
 % extends_config 'hypnotoad', url => 'http://localhost:9999', app => 'MyApp';

 url : http://localhost:9999
 start_mode : hypnotoad
 hypnotoad :
    - heartbeat_timeout : 500

 $ cat > ~/global.conf
 ---
 somevar : somevalue

 $ cat > ~/hypnotoad.conf
 listen :
    - <%= $url %>
 pid_file : <%= $ENV{HOME} %>/<%= $app %>/hypnotoad.pid
 env :
    MOJO_HOME : <%= $ENV{HOME} %>/<%= $app %>

Then later in a program somewhere :

 my $c = Clustericious::Config->new("MyApp");
 my $c = Clustericious::Config->new( \$config_string );
 my $c = Clustericious::Config->new( \%config_data_structure );

 print $c->url;
 print $c->{url};

 print $c->hypnotoad->listen;
 print $c->hypnotoad->{listen};
 my %hash = $c->hypnotoad;
 my @ary  = $c->hypnotoad;

 # Supply a default value for a missing configuration parameter :
 $c->url(default => "http://localhost:9999");
 print $c->this_param_is_missing(default => "something_else");

 # Dump out the entire config as yaml
 print $c->dump_as_yaml;

=head1 DESCRIPTION

Clustericious::Config reads configuration files which are Mojo::Template's
of JSON or YAML files.  There should generally be an entry for
'url', which may be used by either a client or a server depending on
how this node in the cluster is being used.

After rendering the template and parsing the JSON, the resulting
object may be called using method calls or treated as hashes.

Config files are looked for in the following places (in order, where
"MyApp" is the name of the app) :

    $CLUSTERICIOUS_CONF_DIR/MyApp.conf
    $HOME/etc/MyApp.conf
    /util/etc/MyApp.conf
    /etc/MyApp.conf

The helper "extends_config" may be used to read default settings
from another config file.  The first argument to extends_config is the
basename of the config file.  Additional named arguments may be passed
to that config file and used as variables within that file.  After
reading another file, the hashes are merged (i.e. with Hash::Merge);
so values anywhere inside the datastructure may be overridden.

YAML config files must begin with "---", otherwise they are interpreted
as JSON.

Clustericious::Config provides a "get_password" function which will prompt
for a password if it is needed.  It can be used like this :

 password : <%= get_password =%>

This will prompt the user the first time it is encountered.

=head1 METHODS

=over

=cut

package Clustericious::Config;

use Clustericious::Config::Password;

use strict;
use warnings;

our $VERSION = '0.11';

use List::Util qw/first/;
use JSON::XS;
use YAML::XS qw/Load Dump/;
use Mojo::Template;
use Log::Log4perl qw/:easy/;
use Storable qw/dclone/;
use Clustericious::Config::Plugin;
use Data::Dumper;
use Cwd qw/getcwd abs_path/;
use Module::Build;

our %Singletons;

sub _is_subdir {
    my ($child,$parent) = @_;
    my $p = abs_path($parent);
    my $c = abs_path($child);
    return ($c =~ m[^\Q$p\E]) ? 1 : 0;
}

=item new

Create a new Clustericious::Config object.  See the SYPNOSIS for
possible invocations.

=cut

sub new {
    my $class = shift;
    my %t_args = (ref $_[-1] eq 'ARRAY' ? @{( pop )} : () );
    my $arg = $_[0];
    ($arg = caller) =~ s/:.*$// unless $arg; # Determine from caller's class
    return $Singletons{$arg} if exists($Singletons{$arg});

    my $we_are_testing_this_module = 0;
    if ($ENV{HARNESS_ACTIVE} and -d '_build' && -e '_build/build_params' && Module::Build->can("current")) {
        my $mb = Module::Build->current;
        $we_are_testing_this_module = $mb && $mb->module_name eq $arg;
    }

    my $conf_data;

    my $json = JSON::XS->new;
    my $mt = Mojo::Template->new(namespace => 'Clustericious::Config::Plugin')->auto_escape(0);
    $mt->prepend( join "\n", map " my \$$_ = q{$t_args{$_}};", sort keys %t_args );

    my $filename;
    if (ref $arg eq 'SCALAR') {
        my $rendered = $mt->render($$arg);
        die $rendered if ( (ref($rendered)) =~ /Exception/ );
        my $type = $rendered =~ /^---/ ? 'yaml' : 'json';
        $conf_data = $type eq 'yaml' ?
           eval { Load( $rendered ); }
         : eval { $json->decode( $rendered ); };
        LOGDIE "Could not parse $type \n-------\n$rendered\n---------\n$@\n" if $@;
    } elsif (ref $arg eq 'HASH') {
        $conf_data = dclone $arg;
    } elsif (
          $we_are_testing_this_module
          && !(
              $ENV{CLUSTERICIOUS_CONF_DIR}
              && _is_subdir( $ENV{CLUSTERICIOUS_CONF_DIR}, getcwd() )
          )) {
          $conf_data = {};
    } else {
        my @conf_dirs;

        @conf_dirs = $ENV{CLUSTERICIOUS_CONF_DIR} if defined( $ENV{CLUSTERICIOUS_CONF_DIR} );

        push @conf_dirs, ( "$ENV{HOME}/etc", "/util/etc", "/etc" ) unless $we_are_testing_this_module;
        my $conf_file = "$arg.conf";
        my ($dir) = first { -e "$_/$conf_file" } @conf_dirs;
        if ($dir) {
            TRACE "reading from config file $dir/$conf_file";
            $filename = "$dir/$conf_file";
            my $rendered = $mt->render_file("$dir/$conf_file");
            die $rendered if ( (ref $rendered) =~ /Exception/ );
            my $type = $rendered =~ /^---/ ? 'yaml' : 'json';
            if ($ENV{CL_CONF_TRACE}) {
                warn "configuration ($type) : \n";
                warn $rendered;
            }
            $conf_data =
              $type eq 'yaml'
              ? eval { Load($rendered) }
              : eval { $json->decode($rendered) };
            LOGDIE "Could not parse $type\n-------\n$rendered\n---------\n$@\n" if $@;
        } else {
            TRACE "could not find $conf_file file in: @conf_dirs" unless $dir;
            $conf_data = {};
        }
    }
    $conf_data ||= {};
    Clustericious::Config::Plugin->do_merges($conf_data);
    _add_heuristics($filename,$conf_data);
    # Use derived classes so that AUTOLOADING keeps namespaces separate
    # for various apps.
    if ($class eq __PACKAGE__) {
        if (ref $arg) {
            $arg = "$arg";
            $arg =~ tr/a-zA-Z0-9//cd;
        }
        $class = join '::', $class, $arg;
        my $dome = '@'."$class"."::ISA = ('".__PACKAGE__. "')";
        eval $dome;
        die "error setting ISA : $@" if $@;
    }
    bless $conf_data, $class;
}

sub _add_heuristics {
    my $filename = shift;
    # Account for some mojo api changes
    my $conf_data = shift;
    if ($conf_data->{hypnotoad} && !ref($conf_data->{hypnotoad}{listen})) {
        warn "# hypnotoad->listen should be an arrayref in $filename\n";
        $conf_data->{hypnotoad}{listen} = [ $conf_data->{hypnotoad}{listen} ];
    }


}

sub dump_as_yaml {
    my $c = shift;
    return Dump($c);
}

sub _stringify {
    my $self = shift;
    return join ' ', map { ($_, $self->{$_}) } sort keys %$self;
}

sub DESTROY {
}

sub AUTOLOAD {
    my $self = shift;
    my %args = @_;
    my $default = $args{default};
    my $default_exists = exists $args{default};
    our $AUTOLOAD;
    my $called = $AUTOLOAD;
    $called =~ s/.*:://g;
    if ($default_exists && !exists($self->{$called})) {
        $self->{$called} = $args{default};
    }
    unless ($ENV{HARNESS_ACTIVE}) {
        Carp::cluck "config element '$called' not found for ".(ref $self)." (".(join ',',keys(%$self)).")"
            if $called =~ /^_/ || !exists($self->{$called});
    }
    my $value = $self->{$called};
    my $obj;
    my $invocant = ref $self;
    if (ref $value eq 'HASH') {
        $obj = $invocant->new($value);
    }
    no strict 'refs';
    *{ $invocant . "::$called" } = sub {
          my $self = shift;
          $self->{$called} = $default if $default_exists && !exists($self->{$called});
          die "'$called' not found in ".join ',',keys(%$self)
              unless exists($self->{$called});
          my $value = $self->{$called};
          return wantarray && (ref $value eq 'HASH' ) ? %$value
          : wantarray && (ref $value eq 'ARRAY') ? @$value
          :                       defined($obj)  ? $obj
          : Clustericious::Config::Password->is_sentinel($value) ? Clustericious::Config::Password->get
          :                                        $value;
    };
    use strict 'refs';
    $self->$called;
}

=item set_singleton

Clustericicious::Config->set_singleton(App => $object);

Cache a config object to be returned by the constructor.

=cut

sub set_singleton {
    my $class = shift;
    my $app = shift;
    my $obj = shift;
    our %Singletons;
    $Singletons{$app} = $obj;
}

=back

=head1 ENVIRONMENT

If the environment variable HARNESS_ACTIVE is set,
and the current module::build object tells us that
the calling module is being tested, then an empty
configuration is used.  In this situation, however,
if $ENV{CLUSTERICIOUS_CONF_DIR} is set and if it
is a subdirectory of the current directory, then
it will be used.  This allows unit tests to provide
configuration directories, but avoids using configurations
that are outside of the build tree during unit testing.

=head1 NOTES

This is a beta release. The API may change without notice.

=head1 SEE ALSO

L<Mojo::Template>, L<Hash::Merge>, L<Clustericious>, L<Clustericious::Client>

=cut

1;

