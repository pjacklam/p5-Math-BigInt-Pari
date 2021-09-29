# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 3601;

use Scalar::Util qw< refaddr >;

###############################################################################
# Read and load configuration file and backend library.

use Config::Tiny ();

my $config_file = 'xt/author/lib.ini';
my $config = Config::Tiny -> read('xt/author/lib.ini')
  or die Config::Tiny -> errstr();

# Read the library to test.

our $LIB = $config->{_}->{lib};

die "No library defined in file '$config_file'"
  unless defined $LIB;
die "Invalid library name '$LIB' in file '$config_file'"
  unless $LIB =~ /^[A-Za-z]\w*(::\w+)*\z/;

# Read the reference type the library uses.

our $REF = $config->{_}->{ref};

die "No reference type defined in file '$config_file'"
  unless defined $REF;
die "Invalid reference type '$REF' in file '$config_file'"
  unless $REF =~ /^[A-Za-z]\w*(::\w+)*\z/;

# Load the library.

eval "require $LIB";
die $@ if $@;

###############################################################################

can_ok($LIB, '_ssub');

my @data;

# Simple numbers.

my @val = (0 .. 5);
for my $exp (1 .. 9) {
    push @val, 0 + "1e$exp";
}

for my $xa (@val) {
    for my $xs ('+', '-') {
        for my $ya (@val) {
            for my $ys ('+', '-') {
                my $x = $xs . $xa;
                my $y = $ys . $ya;
                my $z = $x - $y;
                my $zs = $z < 0 ? '-' : '+';
                my $za = abs($z);
                push @data, [ $xa, $xs, $ya, $ys, $za, $zs ];
            }
        }
    }
}

# List context.

for (my $i = 0 ; $i <= $#data ; ++ $i) {
    my ($in0, $in1, $in2, $in3, $out0, $out1) = @{ $data[$i] };

    my ($x, $y, @got);
    my $test;

    # $LIB -> _ssub($xabs, $xsgn, $yabs, $ysgn)

    $test = qq|\$x = $LIB->_new("$in0"); |
          . qq|\$y = $LIB->_new("$in2"); |
          . qq|\@got = $LIB->_ssub(\$x, "$in1", \$y, "$in3");|;

    diag("\n$test\n\n") if $ENV{AUTHOR_DEBUGGING};

    eval $test;
    is($@, "", "'$test' gives emtpy \$\@");

    subtest "_ssub() in list context: $test", sub {
        plan tests => 11;

        cmp_ok(scalar(@got), '==', 2,
               "'$test' gives two output args");

        is(ref($got[0]), $REF,
           "'$test' first output arg is a $REF");

        is($LIB->_check($got[0]), 0,
           "'$test' first output arg is valid");

        is($LIB->_str($got[0]), $out0,
           "'$test' first output arg has the right value");

        is(ref($got[1]), '',
           "'$test' second output arg is a scalar");

        is($got[1], $out1,
           "'$test' second output arg has the right value");

        isnt(refaddr($got[0]), refaddr($y),
             "'$test' output arg is not the third input arg");

        is(ref($x), $REF,
           "'$test' first input arg is still a $REF");

        ok($LIB->_str($x) eq $out0 || $LIB->_str($x) eq $in0,
           "'$test' first input arg has the correct value");

        is(ref($y), $REF,
           "'$test' third input arg is still a $REF");

        is($LIB->_str($y), $in2,
           "'$test' third input arg is unmodified");
    };

    # $LIB -> _ssub($xabs, $xsgn, $yabs, $ysgn, 1)

    $test = qq|\$x = $LIB->_new("$in0"); |
          . qq|\$y = $LIB->_new("$in2"); |
          . qq|\@got = $LIB->_ssub(\$x, "$in1", \$y, "$in3", 1);|;

    diag("\n$test\n\n") if $ENV{AUTHOR_DEBUGGING};

    eval $test;
    is($@, "", "'$test' gives emtpy \$\@");

    subtest "_ssub() in list context: $test", sub {
        plan tests => 11;

        cmp_ok(scalar(@got), '==', 2,
               "'$test' gives two output args");

        is(ref($got[0]), $REF,
           "'$test' first output arg is a $REF");

        is($LIB->_check($got[0]), 0,
           "'$test' first output arg is valid");

        is($LIB->_str($got[0]), $out0,
           "'$test' first output arg has the right value");

        is(ref($got[1]), '',
           "'$test' second output arg is a scalar");

        is($got[1], $out1,
           "'$test' second output arg has the right value");

        isnt(refaddr($got[0]), refaddr($x),
             "'$test' output arg is not the first input arg");

        is(ref($x), $REF,
           "'$test' first input arg is still a $REF");

        is($LIB->_str($x), $in0,
           "'$test' first input arg is unmodified");

        is(ref($y), $REF,
           "'$test' third input arg is still a $REF");

        ok($LIB->_str($y) eq $out0 || $LIB->_str($y) eq $in2,
           "'$test' third input arg has the correct value");
    };
}
