package DBD::SQLite::AuthorTests::GetSQLite3;

use strict;
use warnings;
use Config;
use LWP::Simple qw/getstore/;
use DBD::SQLite;
use DBD::SQLite::AuthorTests::Util;

sub get {
  my ($class, $version) = @_;

  $version ||= $DBD::SQLite::sqlite_version;

  my $installed = sqlite3_version();
  if ($installed =~ /^$version/) {
    print "$installed is installed\n";
    return;
  }
  debug("installed: $installed; want: $version");

  if ($^O eq 'MSWin32') {
    $class->get_binary($version);
  }
  else {
    $class->get_and_make($version);
  }
}

sub get_and_make {
  my ($class, $version) = @_;

  my $type = archive_type($version);
  my $tarball = tmpfile("sqlite-$type-".version_for_url($version).".tar.gz");

  unless ($tarball->exists) {
    my $url = join '/', grep defined,
              "http://www.sqlite.org",
              version_year($version),
              $tarball->basename;

    debug("downloading $url to $tarball");
    my $res = getstore($url, $tarball->path);
    if ($res != 200) {
      warn "fetch $url failed: $res\n";
      return;
    }
  }

  require Archive::Tar;

  my $workdir = tmpdir('work')->subdir($version)->mkdir;
  my $tar = Archive::Tar->new($tarball->path);
  for my $file ($tar->list_files) {
    my $path = $file;
    $path =~ s{^sqlite-[^/]+/}{};
    $tar->extract_file($file => $workdir->file($path));
  }

  chdir $workdir;
  debug('configuring');
  system('sh configure');
  debug('making');
  system($Config{make});
  $workdir->file('sqlite3')->copy_to(bindir());

  debug("done");
  return;
}

sub get_binary {
  my ($class, $version) = @_;

  my $zipball = tmpfile("sqlite-shell-win32-x86-".version_for_url($version).".zip");

  unless ($zipball->exists) {
    my $url = join '/', grep defined,
              "http://www.sqlite.org",
              version_year($version),
              $zipball->basename;

    debug("downloading $url to $zipball");
    my $res = getstore($url, $zipball->path);
    if ($res != 200) {
      warn "fetch $url failed: $res\n";
      return;
    }
  }

  require Archive::Zip;

  my $zip = Archive::Zip->new($zipball->path);
  $zip->extractMember("sqlite3.exe", bindir()->file("sqlite3.exe")->path(native => 1));

  debug("done");
  return;
}

sub version_year {
  my $version = shift;
  return 2014 if version_num($version) >= 3080300;
  return 2013 if version_num($version) >= 3071600;
  return;
}

sub version_num {
  my $version = shift;
  sprintf "%u%02u%02u%02u", (split_version($version), 0, 0, 0)[0..3];
}

sub version_dotty {
  my $version = shift;
  my @parts = split_version($version);
  join '.', ($parts[3] ? @parts : @parts[0..2]);
}

sub version_for_url {
  my $version = shift;
  is_old_version($version)
    ? version_dotty($version)
    : version_num($version);
}

sub is_old_version {
  my $version = shift;
  version_num($version) < 3070400 ? 1 : 0;
}

sub archive_type {
  my $version = shift;
  is_old_version($version) ? 'amalgamation' : 'autoconf';
}

sub split_version {
  my $version = shift;

  if ($version =~ m/^[0-9](?:\.[0-9]+){0,3}$/) {
    # $version is X.Y+.Z+.W+ style used for SQLite <= 3.7.3
    return map { (0 + $_) } (split /\./, $version);
  }
  elsif ($version =~ m/^[0-9](?:[0-9]{2}){0,3}$/) {
    # $version is XYYZZWW style used for SQLite >= 3.7.4
    return map { 0 + $_ } ((substr $version, 0, 1),
                            ((substr $version, 1) =~ m/[0-9]{2}/g));
  }
  die "improper <version> format for [$version]\n";
}

1;

__END__

=head1 NAME

DBD::SQLite::AuthorTests::GetSQLite3

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 new

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
