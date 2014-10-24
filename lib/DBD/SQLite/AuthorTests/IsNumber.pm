package DBD::SQLite::AuthorTests::IsNumber;

use strict;
use warnings;
use Exporter::Lite;
use DBI qw/:sql_types/;
use DBD::SQLite::AuthorTests::Util;

our @EXPORT = qw/
  bin_insert dbd_insert dbd_prepared_insert dbd_typed_insert
  bin_select dbd_select
  tweak
/;

my $bin = DBD::SQLite::AuthorTests::Util->sqlite3;
my $db  = DBD::SQLite::AuthorTests::Util->testdb;

# XXX: split into several categories?
my @tests = qw/
  0 1 1.0 1.1 2.0 1.0e+001 0000 01010101 10010101
  0000002100000517
  0000002200000517
  0000001e00000517
  00002.000
  test 01234test -test +test
  0.123e 0.123e+
  0. .123 -.123 +.123
  +0 +1 +2 -0 -1 -2
  -1 -1.0 -1.1 -2.0 -1.0e-001 -0000 -0101 -002.00
  +1 +1.0 +1.1 +2.0 +1.0e-001 +0000 +0101 +002.00
  1234567890123456789012345678901234567890
  -1234567890123456789012345678901234567890
  +1234567890123456789012345678901234567890
  *1234567890123456789012345678901234567890
  -9223372036854775807 +9223372036854775806
  -9223372036854775808 +9223372036854775807
  -9223372036854775809 +9223372036854775808
  -18446744073709551615 +18446744073709551615
  -18446744073709551616 +18446744073709551616
  -18446744073709551617 +18446744073709551617
  -2147483646 +2147483647
  -2147483647 +2147483648
  -2147483648 +2147483649
  -4294967295 +4294967295
  -4294967296 +4294967296
  -4294967297 +4294967297
  + -
/;

sub tests { @tests }

sub is_available { $bin ? 1 : 0 }

sub connect_db {
  my %opts = @_;

  my $testdb = DBD::SQLite::AuthorTests::Util->testdb;

  unlink $testdb if -f $testdb && $opts{cleanup};
  DBI->connect("dbi:SQLite:$testdb", undef, undef, {
    PrintError => 0,
    RaiseError => 0,
    AutoCommit => 1,
    sqlite_allow_multiple_statements => 1,
    sqlite_use_immediate_transaction => 1,
    PrintWarn => ($ENV{TEST_VERBOSE} ? 1 : 0),
  })
}

sub bin_insert {
  my ($value, $type, $quote) = @_;
  my $sql = "create table f (v $type); insert into f values($quote$value$quote)";
  my $testdb = DBD::SQLite::AuthorTests::Util->testdb->path;
  unlink $testdb if -f $testdb;
  my $res = shell($bin, '-list', \$testdb, \$sql);
  debug "BIN: $sql\n$quote$value$quote ($type)";
}

sub dbd_insert {
  my ($value, $type, $quote) = @_;
  my $sql = "create table f (v $type); insert into f values($quote$value$quote)";
  my $dbh = connect_db(cleanup => 1);
  $dbh->do($sql);
  debug "DBD: $sql\n$quote$value$quote ($type)";
}

sub dbd_prepared_insert {
  my ($value, $type, $quote) = @_;
  my $sql = "create table f (v $type); insert into f values(?)";
  my $dbh = connect_db(cleanup => 1);
  $dbh->do("create table f (v $type)");
  my $sth = $dbh->prepare("insert into f values(?)");
  $sth->execute($value);
  debug "DBD(p): $sql\n$quote$value$quote ($type)";
}

sub dbd_typed_insert {
  my ($value, $type, $quote) = @_;
  my $sql = "create table f (v $type); insert into f values(?)";
  my $dbh = connect_db(cleanup => 1);
  $dbh->do("create table f (v $type)");
  my $sth = $dbh->prepare("insert into f values(?)");
  if ($type =~ /integer/) {
    $sth->bind_param(1, $value, SQL_INTEGER);
  }
  elsif ($type =~ /real/) {
    $sth->bind_param(1, $value, SQL_DOUBLE);
  }
  $sth->execute($value);
  if ($sth->err) { warn $sth->errstr }
  debug "DBD(t): $sql\n$quote$value$quote ($type)";
}

sub bin_select {
  my $testdb = DBD::SQLite::AuthorTests::Util->testdb->path;
  my $res = shell($bin, '-list', \$testdb, \'select v,typeof(v) from f');
  debug "BIN: $res\n";
  my ($value, $type) = (split /\|/, $res, 2);
  $value = '' unless defined $value;
  $type  = '' unless defined $type;
  if ($type eq 'real' && $value =~ /\.0$/) { $value = $value + 0 }
  return ($value, $type);
}

sub dbd_select {
  my $dbh = connect_db();
  my ($value, $type) = $dbh->selectrow_array('select v,typeof(v) from f');
  $value = '' unless defined $value;
  $type  = '' unless defined $type;
  debug "DBD: $value|$type\n";
  if ($type eq 'real' && $value =~ /\.0$/) { $value = $value + 0 }
  if ($type eq 'real' && $value =~ /inf/i) { $value = 'Inf' }
  return ($value, $type);
}

sub tweak {
  my ($binres, $dbdres) = @_;
  return unless $binres->[1] eq 'real' && $dbdres->[1] eq 'real';
  if ($binres->[0] =~ /^([+-]?)\d+\.(\d+)(e\+\d+)?$/) {
    my $prec = length($2);
    my $format = ((($1 || '') eq '+') ? '+' : '') ."%.${prec}f";
    if (my ($exp) = $dbdres->[0] =~ /(e\+\d+)$/) {
      $exp =~ s/^e\+0+/e+/;
      $dbdres->[0] =~ s/(e\+\d+)$//;
      $dbdres->[0] = (sprintf $format, $dbdres->[0]) . ($exp ? $exp : '');
    }
  }
}

1;

__END__

=head1 NAME

DBD::SQLite::AuthorTests::IsNumber

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 tests

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
