#!/usr/bin/env perl -T

use strict;
use warnings;

use Test::Most tests => 1;

BEGIN {
	require_ok( 'FindLib' );
}

diag( "Testing FindLib $FindLib::VERSION, Perl $], $^X" );
