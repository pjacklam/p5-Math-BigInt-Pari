#!perl

use strict;

# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

# The name of your distribution
name		'Math-BigInt-Pari';

# Get most of the details from the primary module
all_from	'lib/Math/BigInt/Pari.pm';

requires	'perl'		=> '5.006002';
requires	'Math::BigInt'	=> '1.999709';
requires	'Math::Pari'	=> '2.010709';

test_requires	'Test::More'	=> 0.47;

license		'perl';

author		'Peter John Acklam <pjacklam@gmail.com>';

sign;

# Generate the Makefile
WriteAll;
