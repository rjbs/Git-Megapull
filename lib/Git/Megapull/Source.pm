use strict;
use warnings;
package Git::Megapull::Source;
# ABSTRACT: a source of cloneable git repository URIs

=head1 OVERVIEW

This will be a base class for sources for Git::Megapull.  Right now, it does
nothing.

See L<Git::Megapull>.

=cut

sub new {
    my $class = shift;
    my ($opt) = @_ == 1 ? $_[0] : {@_};
    $opt->{remote} = 'origin' unless exists $opt->{remote};
    bless $opt, $class;
}

sub update_all {
  my $self = shift;
  my $repos = $self->repo_uris(@_);

  my %existing_dir  = map { $_ => 1 } grep { $_ !~ m{\A\.} and -d $_ } <*>;

  for my $name (sort { $a cmp $b } keys %$repos) {
    my $name = $name;
    my $uri  = $repos->{ $name };

    if (-d $name) {
      if (not $self->{clonely}) {
        $self->update_repo($name, $uri);
      }
    } else {
      $self->clone_repo($name, $uri);
    }

    delete $existing_dir{ $name };
  }

  for (keys %existing_dir) {
    warn "unknown directory found: $_\n";
  }
}

sub clone_repo {
  my ($self, $name, $uri) = @_;

  my $bare = $self->{bare} ? '--bare' : '';
  $self->_do_cmd("git clone -o $self->{remote} $bare $uri 2>&1");
}

sub update_repo {
  my ($self, $name, $uri) = @_;

  $self->_do_cmd(
    "cd $name && "
    . "git fetch $self->{remote} && "
    . "git merge $self->{remote}/master 2>&1"
  );
}

sub repo_uris {
    die "Sources must define a repo_uris method";
}

sub _do_cmd {
  my ($self, $cmd) = @_;
  print "$cmd\n";
  system("$cmd");
}

1;
