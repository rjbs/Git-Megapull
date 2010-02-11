use strict;
use warnings;
package Git::Megapull;
use base 'App::Cmd::Simple';
# ABSTRACT: clone or update all repositories found elsewhere

use autodie;
use Config::INI::Reader;
use String::RewritePrefix;

=head1 OVERVIEW

This library implements the C<git-megaclone> command, which will find a list of
remote repositories and clone them.  If they already exist, they will be
updated from their remotes, instead.

=head1 USAGE

  git-megapull [-bcs] [long options...]
    -b --bare       produce bare clones
    -c --clonely    only clone things that do not exist; skip others
    -s --source     the source class (or a short form of it)

The source may be given as a full Perl class name prepended with an equals
sign, like C<=Git::Megapull::Source::Github> or as a short form, dropping the
standard prefix.  The previous source, for example, could be given as just
C<Github>.

If no C<--source> option is given, the F<megapull.source> option in
F<~/.gitconfig> will be consulted.

=head1 TODO

  * prevent updates that are not fast forwards
  * do not assume "master" is the correct branch to merge

=head1 WRITING SOURCES

Right now, the API for how sources work is pretty lame and likely to change.
Basically, a source is a class that implements the C<repo_uris> method, which
receives a hashref of the contents of the user's .gitconfig and an arrayref of
extra arguments to the command, and returns a hashref like C<< { $repo_name =>
$repo_uri, ... } >>.  This is likely to be changed slightly to instantiate
sources with parameters and to allow repos to have more attributes than a name
and URI.

=cut

sub opt_spec {
  return (
    # [ 'private|p!', 'include private repositories'     ],
    [ 'bare|b!',    'produce bare clones'                              ],
    [ 'clonely|c',  'only clone things that do not exist; skip others' ],
    [ 'remote=r',   'name to use when creating or fetching; default: origin',
                    { default => 'origin' }                            ],
    [ 'source|s=s', "the source class (or a short form of it)",
                    { default => $ENV{GIT_MEGAPULL_SOURCE} }           ],
  );
}

sub execute {
  my ($self, $opt, $args) = @_;

  my $config = Config::INI::Reader->read_file("$ENV{HOME}/.gitconfig");

  my $source = $opt->{source};
  unless ($source) {
    $source = $config->{megapull}{source};
  }

  $source ||= $self->_default_source;

  $self->usage_error("no source provided") unless $source;

  $source = String::RewritePrefix->rewrite(
    { '' => 'Git::Megapull::Source::', '=' => '' },
    $source,
  );

  # XXX: validate $source as module name -- rjbs, 2009-09-13
  # XXX: validate $opt->{remote} -- rjbs, 2009-09-13

  eval "require $source; 1" or die;

  die "bad source: not a Git::Megapull::Source\n"
    unless eval { $source->isa('Git::Megapull::Source') };

  my $s = $source->new($opt);

  $s->update_all(@$args);
}

sub _default_source {}
1;
