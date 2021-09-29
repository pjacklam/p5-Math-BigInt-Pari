# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More;

# Ensure a recent version of Test::Pod::Coverage

my $min_tpc = 1.08;
eval "use Test::Pod::Coverage $min_tpc";
plan skip_all => "Test::Pod::Coverage $min_tpc required for testing POD coverage"
  if $@;

# Test::Pod::Coverage doesn't require a minimum Pod::Coverage version,
# but older versions don't recognize some common documentation styles

my $min_pc = 0.18;
eval "use Pod::Coverage $min_pc";
plan skip_all => "Pod::Coverage $min_pc required for testing POD coverage"
  if $@;

my $trustme = {
               private => [ qr/^__/,
                            qr/^(un)?import$/,
                            #qr/^DESTROY$/,
                            #qr/^bootstrap$/,
                          ],
               trustme => [ 'api_version',
                            '_mp2oct',
                            '_mp2os',
                            '_set',
                          ],
               coverage_class => 'Pod::Coverage::CountParents',
              };

all_pod_coverage_ok($trustme, "All modules are covered");
