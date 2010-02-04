use strict;
use warnings;
package Git::Megapull::Source::Text;
use base 'Git::Megapull::Source';
# ABSTRACT: clone/update all your repositories from a text file

use Config::Any;

sub repo_uris {
    my $self = shift;
    my ($config, $args) = @_;
    my $filename;
    if (@$args) {
        $filename = $args->[0];
    }
    elsif (exists $config->{megapull}{text}) {
        $filename = $config->{megapull}{text};
    }
    die "Must provide a filename" unless $filename;

    return Config::Any->load_files({
        files           => [$filename],
        use_ext         => 1,
        flatten_to_hash => 1
    })->{$filename};
}

1;
