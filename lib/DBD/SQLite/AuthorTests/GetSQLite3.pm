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

  if ($version =~ /^3\./) {
    $version = sprintf "%u%02u%02u%02u", (split /\./, $version), (0, 0, 0);
  }

  my $is_pre374  = $version < 3070400 ? 1 : 0;
  if ($is_pre374) {
    my @parts = $version =~ /(3)(\d\d)(\d\d)(\d\d)/;
    $version = join '.', grep $_, @parts
  }

  if ($^O eq 'MSWin32') {
    $class->get_binary($version, $is_pre374);
  }
  else {
    $class->get_and_make($version, $is_pre374);
  }
}

sub get_and_make {
  my ($class, $version, $is_pre374) = @_;

  my $tarball = tmpfile("sqlite-$version.tar.gz");

  unless ($tarball->exists) {
    my $year = ($version >= 3071600) ? "2013/" : "";
    my $url = join '-', 'http://www.sqlite.org/${year}sqlite',
                        ($is_pre374 ? 'amalgamation' : 'autoconf'),
                        "$version.tar.gz";

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

  my $zipball = tmpfile("sqlite-shell-win32-x86-$version.zip");

  unless ($zipball->exists) {
    my $year = ($version >= 3071600) ? "2013/" : "";
    my $url = "http://www.sqlite.org/$year" . $zipball->basename;

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
