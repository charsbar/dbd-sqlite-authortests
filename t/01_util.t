use strict;
use warnings;
use Test::More;
use DBD::SQLite::AuthorTests::Util;

{
  my $root = root();
  ok $root, "root: $root";
}

done_testing;
