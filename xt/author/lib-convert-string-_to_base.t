# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 17739;

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

# Load the library.

eval "require $LIB";
die $@ if $@;

###############################################################################

can_ok($LIB, '_to_base');

my @data;

my $max = 0x7fffffff;   # 2**31-1 (max value for a 32 bit signed int)

# Small numbers and other simple tests.

for (my $x = 0; $x <= 255 ; ++ $x) {
    push @data, [ $x,  2, sprintf("%b", $x) ];
    push @data, [ $x,  8, sprintf("%o", $x) ];
    push @data, [ $x, 10, sprintf("%d", $x) ];
    push @data, [ $x, 16, sprintf("%X", $x) ];
}

my $collseq = '0123456789'                      #  48 ..  57
            . 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'      #  65 ..  90
            . 'abcdefghijklmnopqrstuvwxyz'      #  97 .. 122
            . '!"#$%&\'()*+,-./'                #  33 ..  47
            . ':;<=>?@'                         #  58 ..  64
            . '[\\]^_`'                         #  91 ..  96
            . '{|}~';                           # 123 .. 126

for my $base (2 .. 94) {

    # Zero is converted to "0", regardless of base and collation sequence.

    push @data, [ "0", $base,           "0" ];
    push @data, [ "0", $base, $collseq, "0" ];

    # Increasing integer powers of the base, with a collation sequence of
    # "01..." gives "1", "10", "100", "1000", ...

    for (my $pow = 0 ; ; $pow++) {
        my $x = $base ** $pow;
        last if $x > $max;
        push @data, [ $x, $base,           '1' . ('0' x $pow) ];
        push @data, [ $x, $base, $collseq, '1' . ('0' x $pow) ];
    }

    # b^n-1 gives a string containing only one or more of the last character in
    # the collation sequence. E.g.,
    #    b =  2, n = 4, 2^4-1 -> "1111"
    #    b = 10, n = 5, 10^5-1 -> "99999"
    #    b = 16, n = 6, 10^6-1 -> "FFFFFF"

    for (my $pow = 1 ; ; $pow++) {
        my $x = $base ** $pow - 1;
        last if $x > $max;
        my $chr = substr $collseq, $base - 1, 1;
        push @data, [ $x, $base,           $chr x $pow ];
        push @data, [ $x, $base, $collseq, $chr x $pow ];
    }
}

#     "123" in base "10" is "123"
#   "10203" in base "100" is "123"
# "1002030" in base "1000" is "123"
# ...

for my $exp (1 .. 100) {
    my $sep  = "0" x ($exp - 1);
    my $x    = join($sep, "1", "2", "3");
    my $base =  "1" . ("0" x $exp);
    my $str  = "123";
    push @data, [ $x, $base, $collseq, $str ];
}

{
    my $collseq = '-|';
    for my $base (2 .. 100) {
        for (my $pow = 0 ; ; $pow++) {
            my $x = $base ** $pow;
            last if $x > $max;
            my $str = '|' . ('-' x $pow);
            push @data, [ $x, $base, $collseq, $str ];
        }
    }
}

# Add data in data file.

(my $datafile = $0) =~ s/\.t/.dat/;
open DATAFILE, $datafile or die "$datafile: can't open file for reading: $!";
while (<DATAFILE>) {
    s/\s+\z//;
    next if /^#/ || ! /\S/;
    push @data, [ split /:/ ];
}
close DATAFILE or die "$datafile: can't close file after reading: $!";

# List context.

for (my $i = 0 ; $i <= $#data ; ++ $i) {
    my @in   = @{ $data[$i] };
    my $out0 = pop @in;

    my ($x, @got);

    # Collation sequence. Make an escaped version for display purposes.

    my ($cs, $csesc);
    if (@in == 3) {
        $cs = $in[2];
        ($csesc = $cs) =~ s|([\@\$`"\\])|\\$1|g;
    }

    # We test with the base given as a scalar and as a reference. We also
    # accept test data with and without a collation sequence.

    for my $base_as_scalar (0, 1) {

        # To avoid integer overflow, don't test with a large, scalar base.

        next if $base_as_scalar && $in[1] > $max;

        my $test = qq|\$x = $LIB->_new("$in[0]");|;
        $test .= $base_as_scalar ? qq| \$b = $in[1];|
                                 : qq| \$b = $LIB->_new("$in[1]");|;
        $test .= @in == 3 ? qq| \@got = $LIB->_to_base(\$x, \$b, "$csesc")|
                          : qq| \@got = $LIB->_to_base(\$x, \$b)|;

        $x = $LIB->_new($in[0]);
        $b = $base_as_scalar ? $in[1]
                             : $LIB->_new($in[1]);
        @got = @in == 3 ? $LIB->_to_base($x, $b, $cs)
                        : $LIB->_to_base($x, $b);

        diag("\n$test\n\n") if $ENV{AUTHOR_DEBUGGING};

        subtest "_to_base() in list context: $test", sub {
            plan tests => 3,

            cmp_ok(scalar @got, '==', 1,
                   "'$test' gives one output arg");

            is(ref($got[0]), "",
               "'$test' output arg is a scalar");

            is($got[0], $out0,
               "'$test' output arg has the right value");
        };
    }
}

# Scalar context.

for (my $i = 0 ; $i <= $#data ; ++ $i) {
    my @in   = @{ $data[$i] };
    my $out0 = pop @in;

    my ($x, $got);

    # Collation sequence. Make an escaped version for display purposes.

    my ($cs, $csesc);
    if (@in == 3) {
        $cs = $in[2];
        ($csesc = $cs) =~ s|([\@\$`"\\])|\\$1|g;
    }

    # We test with the base given as a scalar and as a reference. We also
    # accept test data with and without a collation sequence.

    for my $base_as_scalar (0, 1) {

        # To avoid integer overflow, don't test with a large, scalar base.

        next if $base_as_scalar && $in[1] > $max;

        my $test = qq|\$x = $LIB->_new("$in[0]");|;
        $test .= $base_as_scalar ? qq| \$b = $in[1];|
                                 : qq| \$b = $LIB->_new("$in[1]");|;
        $test .= @in == 3 ? qq| \$got = $LIB->_to_base(\$x, \$b, "$csesc")|
                          : qq| \$got = $LIB->_to_base(\$x, \$b)|;

        $x = $LIB->_new($in[0]);
        $b = $base_as_scalar ? $in[1]
                             : $LIB->_new($in[1]);
        $got = @in == 3 ? $LIB->_to_base($x, $b, $cs)
                        : $LIB->_to_base($x, $b);

        diag("\n$test\n\n") if $ENV{AUTHOR_DEBUGGING};

        subtest "_to_base() in scalar context: $test", sub {
            plan tests => 2,

            is(ref($got), "",
               "'$test' output arg is a scalar");

            is($got, $out0,
               "'$test' output arg has the right value");
        };
    }
}
