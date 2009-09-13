use strict;
use warnings;
package Git::Megapull::Source::Github;
# ABSTRACT: clone/update all your repositories from github.com

use LWP::Simple qw(get);
use Config::INI::Reader;
use JSON::XS;

=head1 OVERVIEW

This source for C<git-megapull> will look for a C<github> section in the file
F<~/.gitconfig>, and will use the login and token entries to auth with the
GitHub API, and get a list of your repositories.

=head1 WARNING

This source will probably be broken out into its own dist in the future.

=head1 TODO

  * add means to include/exclude private repos
  * add means to use alternate credentials
  * investigate using Github::API

=method repo_uris

This routine does all the work and returns what Git::Megapull expects: a
hashref with repo names as keys and repo URIs as values.

=cut

sub repo_uris {
  my $config  = Config::INI::Reader->read_file("$ENV{HOME}/.gitconfig");
  my $login   = $config->{github}{login} || die "no github login\n";
  my $token   = $config->{github}{token} || die "no github token\n";

  my $json =
    get("http://github.com/api/v1/json/$login?login=$login&token=$token");

  my $data = eval { JSON::XS->new->decode($json) };

  die "BAD JSON\n$@\n$json\n" unless $data;

  my @repos = @{ $data->{user}{repositories} };

  my %repo_uri;
  for my $repo (@repos) {
    $repo_uri{ $repo->{name} } = sprintf 'git@github.com:%s/%s.git',
      $login,
      $repo;
  }

  return \%repo_uri;
}

1;
