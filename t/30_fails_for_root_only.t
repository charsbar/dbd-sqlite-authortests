#!/usr/bin/env perl

# http://paste.scsys.co.uk/206600
# reported by frew (#dbix-class @irc.perl.org)

use strict;
use warnings;
use Test::More;
use Test::Fatal;
use File::Copy 'move';
use DBI;

my $file = 'test.db';
my $db_tmp = 'test.db.tmp';
my $dbh = DBI->connect('dbi:SQLite:dbname=test.db', '', '', {RaiseError => 1});
$dbh->do(q{create table test (id integer primary key, name varchar(30))});
$dbh->do(q{insert into test(name) VALUES(?)}, {}, $_) for qw(frew bar baz);

my $sth = $dbh->prepare('SELECT COUNT(*) as foo FROM test');
$sth->execute;
is ($sth->fetchrow_hashref->{foo}, 3, 'actually connected');

move $file, "$file.tmp" or die "could not move file: $!";

{
open my $tmp, '>', $file;
print $tmp 'THIS IS NOT A REAL DATABASE';
close $tmp;
chmod 0000, $file;
}

{
  my $w;
  local $SIG{__WARN__} = sub { $w = shift };
  $dbh->disconnect;
  ok ($w !~ /active statement handles/, 'SQLite can disconnect properly');
}

like(
   exception {
      $dbh = DBI->connect('dbi:SQLite:dbname=test.db', '', '', {RaiseError => 1});
      $dbh->do(q{select * from test});
   },
   qr/unable to open database file/,
   'cannot read db'
);

unlink($file) or die "could not delete $file: $!";
move( $db_tmp, $file )
  or die "could not move $db_tmp to $file: $!";

$dbh = DBI->connect('dbi:SQLite:dbname=test.db', '', '', {RaiseError => 1});

### Try the operation again... this time, it should succeed
ok( !exception {
   $dbh->do(q{select * from test}),
}, 'The operation succeeded');

done_testing;

END {
   unlink 'test.db';
   unlink 'test.db.tmp';
}

__END__

tungsten [27637] ~/tmp $ /usr/bin/perl foo.pl 
ok 1 - actually connected
ok 2 - SQLite can disconnect properly
ok 3 - cannot read db
ok 4 - The operation succeeded
1..4
tungsten [27638] ~/tmp $ sudo /usr/bin/perl foo.pl
ok 1 - actually connected
ok 2 - SQLite can disconnect properly
DBD::SQLite::db do failed: file is encrypted or is not a database at foo.pl line 39.
not ok 3 - cannot read db
#   Failed test 'cannot read db'
#   at foo.pl line 41.
#                   'DBD::SQLite::db do failed: file is encrypted or is not a database at foo.pl line 39.
# '
#     doesn't match '(?^:unable to open database file)'
ok 4 - The operation succeeded
1..4
# Looks like you failed 1 test of 4.
