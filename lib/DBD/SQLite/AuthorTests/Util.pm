package DBD::SQLite::AuthorTests::Util;

use strict;
use warnings;
use Exporter::Lite;
use DBD::SQLite;
use Path::Extended;

our @EXPORT = qw/
  debug shell
  root tmpdir tmpfile bindir
  sqlite3_version
/;
our $IS_WIN = $^O eq 'MSWin32';

sub sqlite3 {
  my $bin = __PACKAGE__->bindir->file($IS_WIN ? "sqlite3.exe" : "sqlite3");
  return $bin->exists ? $bin : undef;
}

sub testdb { tmpfile('test.db') }

sub sqlite3_version {
  my $bin = sqlite3() or return '';
  shell($bin, "--version");
}

sub dbd_sqlite_version { $DBD::SQLite::sqlite_version; }

sub shell { # only works for simple cases
  my @args = @_;
  my $quote = q{'};
  if ($IS_WIN) {
    $quote = q{"};
    for my $arg (@args) {
      if (ref $arg eq ref \'') {
        my $new_arg = $$arg;
        $new_arg =~ s{"}{'}g;
        $arg = \$new_arg;
      }
    }
  }
  my $str = join " ", map { ref $_ eq  ref \'' ? "$quote${$_}$quote" : $_ } @args;
  my $res = `$str 2>&1`;
  chomp $res;
  $res;
}

sub root {
  my $dir = file(__FILE__)->parent;
  until ($dir->file('Makefile.PL')->exists or $dir->parent eq $dir) {
    $dir = $dir->parent;
  }
  $dir or die "Can't find app root\n";
}

sub tmpdir {
  __PACKAGE__->root->subdir("tmp")->mkdir;
}

sub tmpfile {
  __PACKAGE__->tmpdir->file(@_);
}

sub bindir {
  __PACKAGE__->root->subdir("bin")->mkdir;
}

sub debug { print @_, "\n" unless $ENV{HARNESS_ACTIVE} }

1;

__END__

=head1 NAME

DBD::SQLite::AuthorTests::Util

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
