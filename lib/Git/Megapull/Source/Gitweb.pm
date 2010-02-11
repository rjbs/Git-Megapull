use strict;
use warnings;
package Git::Megapull::Source::Gitweb;
use base 'Git::Megapull::Source';
# ABSTRACT: clone/update all your repositories from a gitweb installation

use Term::ReadKey;
use LWP::UserAgent;
use Getopt::Long qw(GetOptionsFromArray);

=head1 OVERVIEW

This source for C<git-megapull> introspects a Gitweb installation to determine the list of projects to clone. It requires a few extra options:
C<< --url=<some url> >> to specify the url of the gitweb installation, and
either C<--anon> or C<< --user=<ssh username> >> to specify how to actually
clone the repositories. C<--anon> will use a repository url of the form
B<git://base.url.com/Project.git>, and C<--user> will use a repository url of
the form B<user@base.url.com:Project.git>.

If the gitweb installation requires an HTTP username and password, this source
will prompt you for them.

=head1 WARNING

This source will probably be broken out into its own dist in the future.

=head1 TODO

  * see if there's a better way to get the repo list

=method repo_uris

This routine does all the work and returns what Git::Megapull expects: a
hashref with repo names as keys and repo URIs as values.

=cut

sub repo_uris {
    my $self = shift;
    my (@args) = @_;
    my ($url, $user, $anon);
    GetOptionsFromArray(
        \@args,
        'url=s'  => \$url,
        'user=s' => \$user,
        'anon'   => \$anon
    ) or die;

    die "Need a url" unless $url;

    (my $base_url = $url) =~ s+https?://++;
    $base_url =~ s+/.*++;
    my $ua = LWP::UserAgent->new;
    my $res = $ua->get("$url?a=project_index");
    if (!$res->is_success && $res->code == 401) {
        END { ReadMode 0 }
        ReadMode 1;
        print "Username: ";
        my $user = ReadLine 0;
        chomp $user;
        ReadMode 2;
        print "Password: ";
        my $pass = ReadLine 0;
        chomp $pass;
        ReadMode 0;
        print "\n";
        my $netloc = $base_url;
        if ($netloc =~ s/:(\d+)$//) {
            $netloc = "$netloc:$1";
        }
        elsif ($url =~ /^https/) {
            $netloc = "$netloc:443";
        }
        else {
            $netloc = "$netloc:80";
        }
        (my $realm = $res->header('www-authenticate')) =~ s/Basic realm="(.*)"/$1/;
        $ua->credentials($netloc, $realm, $user, $pass);
        $res = $ua->get("$url?a=project_index");
    }
    if (!$res->is_success) {
        use Data::Dumper;
        die Dumper($res);
    }
    my $url_data = $res->content;
    my @repos = map { s/ .*$//; $_ } split /\n/, $url_data;
    my @names = @repos;
    @names = map { s+.*/++; s+\.git$++; $_ } @names;
    if ($anon) {
        @repos = map { "git://$base_url/$_" } @repos;
    }
    else {
        die "Need a username" unless $user;
        @repos = map { s+.*/++; "$user\@$base_url:$_" } @repos;
    }
    my %repos = map { $names[$_], $repos[$_] } 0..$#repos;
    return \%repos;
}

1;
