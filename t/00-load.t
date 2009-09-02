#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'FindLib' );
}

diag( "Testing FindLib $FindLib::VERSION, Perl $], $^X" );
