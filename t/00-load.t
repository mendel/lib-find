#!/usr/bin/env perl -T

use strict;
use warnings;

use Test::Most tests => 1;

BEGIN {
	require_ok( 'lib::find' );
}

diag( "Testing lib::find $lib::find::VERSION, Perl $], $^X" );
