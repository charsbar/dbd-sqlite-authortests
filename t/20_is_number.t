use strict;
use warnings;
use Test::More;
use Test::Differences qw/eq_or_diff/;
use DBD::SQLite::AuthorTests::IsNumber;

unless (DBD::SQLite::AuthorTests::IsNumber->is_available) {
  plan skip_all => "requires sqlite3";
}

for my $quote ('"', '') {
  for my $value (DBD::SQLite::AuthorTests::IsNumber->tests) {
    for my $type ('', 'integer', 'unsigned integer', 'real', 'unsigned real', 'text', 'integer primary key', 'bigint', 'unsigned bigint') {
      bin_insert($value, $type, $quote);
      my @bb = bin_select();
      my @bd = dbd_select();
      tweak(\@bb, \@bd);
      eq_or_diff \@bd => \@bb, "bin->DBD: v: $value, t: $type, q: $quote";

      dbd_insert($value, $type, $quote);
      my @db = bin_select();
      my @dd = dbd_select();
      tweak(\@db, \@dd);
      eq_or_diff \@db => \@bb, "DBD->bin: v: $value, t: $type, q: $quote";
      eq_or_diff \@dd => \@bb, "DBD->DBD: v: $value, t: $type, q: $quote";

      if ($quote) {
        dbd_prepared_insert($value, $type, $quote);
        my @dpb = bin_select();
        my @dpd = dbd_select();
        tweak(\@dpb, \@dpd);
        eq_or_diff \@dpb => \@bb, "DBD(p)->bin: v: $value, t: $type, q: $quote";
        eq_or_diff \@dpd => \@bb, "DBD(p)->DBD: v: $value, t: $type, q: $quote";
      }

      if ($quote) {
        dbd_typed_insert($value, $type, $quote);
        my @dtb = bin_select();
        my @dtd = dbd_select();
        tweak(\@dtb, \@dtd);
        eq_or_diff \@dtb => \@bb, "DBD(t)->bin: v: $value, t: $type, q: $quote";
        eq_or_diff \@dtd => \@bb, "DBD(t)->DBD: v: $value, t: $type, q: $quote";
      }
    }
  }
}

done_testing;
