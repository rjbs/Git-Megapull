use strict;
use warnings;
package Git::Megapull::Source::Github;

use LWP::Simple qw(get);
use Config::INI::Reader;
use JSON::XS;

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
