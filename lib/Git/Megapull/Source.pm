use strict;
use warnings;
package Git::Megapull::Source;
# ABSTRACT: a source of cloneable git repository URIs

=head1 OVERVIEW

This is the base class for sources for L<Git::Megapull>. It defines some
methods for updating repositories from the given source.

=cut

=head1 METHODS

=cut

=head2 new

Takes a hash of options:

=over 4

=item remote

The name of the remote to fetch from when updating, and the remote to create
when cloning. Defaults to C<origin>.

=item bare

Boolean determining whether or not to create bare repositories. Defaults to
false.

=item clonely

Only clone repositories that don't exist, do not update existing ones. Defaults
to false.

=back

=cut

sub new {
    my $class = shift;
    my ($opt) = @_ == 1 ? $_[0] : {@_};
    $opt->{remote} = 'origin' unless exists $opt->{remote};
    bless $opt, $class;
}

=head2 update_all

Updates all repositories given by the C<repo_uris> method. Clones them if the
directory doesn't exist, does a fetch and merge otherwise. Passes any arguments
given along to C<repo_uris>.

=cut

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

=head2 clone_repo($name, $uri)

Clones a new repository from C<$uri>.

=cut

sub clone_repo {
  my ($self, $name, $uri) = @_;

  my $bare = $self->{bare} ? '--bare' : '';
  $self->_do_cmd("git clone -o $self->{remote} $bare $uri 2>&1");
}

=head2 clone_repo($name, $uri)

Updates (fetch + merge) an existing repository at C<$uri>.

=cut

sub update_repo {
  my ($self, $name, $uri) = @_;

  $self->_do_cmd(
    "cd $name && "
    . "git fetch $self->{remote} && "
    . "git merge $self->{remote}/master 2>&1"
  );
}

=head2 repo_uris

Abstract method, to be overridden in subclasses. Should return a hash mapping
repository names to uris.

=cut

sub repo_uris {
    die "Sources must define a repo_uris method";
}

sub _do_cmd {
  my ($self, $cmd) = @_;
  print "$cmd\n";
  system("$cmd");
}

1;
