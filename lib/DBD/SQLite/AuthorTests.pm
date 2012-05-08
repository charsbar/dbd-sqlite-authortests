package DBD::SQLite::AuthorTests;

use strict;
use warnings;

our $VERSION = '0.01';

1;

__END__

=head1 NAME

DBD::SQLite::AuthorTests - author tests for DBD::SQLite

=head1 DESCRIPTION

This is a collection of author tests that I'm not willing to add to the main DBD::SQLite repository. This is not meant to be installed via CPAN clients; just clone this from the repository (github), checkout/export DBD::SQLite under a subdirectory of the directory where you cloned this (if necessary), run C<perl Makefile.PL && make && make test>, and see what happens.

=head1 CAVEATS FOR WIN32

The tests should run, but you probably need to set up a few things by hand.

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
