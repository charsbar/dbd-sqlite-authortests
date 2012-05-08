use strict;
use warnings;
use Test::More;
use DBD::SQLite::AuthorTests::Util;
use DBD::SQLite::AuthorTests::GetSQLite3;

DBD::SQLite::AuthorTests::GetSQLite3->get;

my $installed = DBD::SQLite::AuthorTests::Util->sqlite3_version;
ok $installed, "installed sqlite3 version: $installed";

done_testing;
