use strict;
use warnings;
package Git::Megapull;
use base 'App::Cmd::Simple';

use autodie;
use String::RewritePrefix;

sub opt_spec {
  return (
    # [ 'private|p!', 'include private repositories'     ],
    [ 'bare|b!',    'produce bare clones'                              ],
    [ 'clonely|c',  'only clone things that do not exist; skip others' ],
    [ 'source|s=s', "the source class (or a short form of it)",
                    { default => $ENV{GIT_MEGAPULL_SOURCE} }           ],
  );
}

sub execute {
  my ($self, $opt, $args) = @_;

  $self->usage_error("no source provided") unless $opt->{source};

  my $source = String::RewritePrefix->rewrite(
    { '' => 'Git::Megapull::Source::', '=' => '' },
    $opt->{source},
  );

  # XXX: validate $source as module name -- rjbs, 2009-09-13

  eval "require $source; 1" or die;
  my $repos = $source->repo_uris;

  my %existing_dir  = map { $_ => 1 } grep { $_ !~ m{\A\.} and -d $_ } <*>;

  for my $name (sort { $a cmp $b } keys %$repos) {
    # next if $repo->{private} and not $opt->{private};

    my $name = $name;
    my $uri  = $repos->{ $name };

    if (-d $name) {
      __do_cmd("cd $name && git fetch origin && git merge origin/master 2>&1")
        unless $opt->{clonely};
    } else {
      my $bare = $opt->{bare} ? '--bare' : '';
      __do_cmd("git clone $bare $uri 2>&1");
    }

    delete $existing_dir{ $name };
  }

  for (keys %existing_dir) {
    warn "unknown directory found: $_\n";
  }
}

sub __do_cmd {
  my ($cmd) = @_;
  print "$cmd\n";
  print `$cmd`;
}

1;
