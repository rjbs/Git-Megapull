use strict;
use warnings;
package Git::Megapull::Source::Text;
use base 'Git::Megapull::Source';
# ABSTRACT: clone/update all your repositories from a text file

use Config::Any;

=head1 OVERVIEW

This source for C<git-megapull> will read in a text file given on the command
line, and try to parse it as a single hash, in some format recognized by
L<Config::Any>. The keys for the hash should be repository names, and the
values should be the corresponding urls.

=head1 WARNING

This source will probably be broken out into its own dist in the future.

=method repo_uris

This routine does all the work and returns what Git::Megapull expects: a
hashref with repo names as keys and repo URIs as values.

=cut

sub repo_uris {
    my $self = shift;
    my (@args) = @_;

    my $filename;
    if (@args) {
        $filename = $args[0];
    }
    else {
        my $config = Config::INI::Reader->read_file("$ENV{HOME}/.gitconfig");
        if (exists $config->{megapull}{text}) {
            $filename = $config->{megapull}{text};
        }
    }
    die "Must provide a filename" unless $filename;

    return Config::Any->load_files({
        files           => [$filename],
        use_ext         => 1,
        flatten_to_hash => 1
    })->{$filename};
}

1;
