#!/usr/bin/perl -w

use strict;             # restrict unsafe constructs

use Test::More tests => 2;

BEGIN {
    use_ok('Math::BigInt::Pari');
    use_ok('Math::BigInt');         # Math::BigInt is required for the tests
};

diag("Testing Math::BigInt::Pari $Math::BigInt::Pari::VERSION");
diag("==> Perl $], $^X");
diag("==> Math::BigInt $Math::BigInt::VERSION");
