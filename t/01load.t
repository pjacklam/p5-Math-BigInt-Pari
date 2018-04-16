#!perl

use strict;             # restrict unsafe constructs
use warnings;           # enable optional warnings

use Test::More tests => 2;

BEGIN {
    use_ok('Math::BigInt::Pari');
    use_ok('Math::BigInt');         # Math::BigInt is required for the tests
};

my @mods = ('Math::BigInt::Pari',
            'Math::BigInt',
            'Math::Pari');

diag("");
diag("Testing with Perl $], $^X");
diag("");
diag(sprintf("%12s %s\n", 'Version', 'Module'));
diag(sprintf("%12s %s\n", '-------', '------'));
for my $mod (@mods) {
    diag(sprintf("%12s %s\n", $mod -> VERSION, $mod));
}
diag("");
