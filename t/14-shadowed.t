#!/usr/bin/perl

use strict;
use warnings;

use FindBin;

use Test::Most;

use FindLib ();

{
  my $base_dir = "$FindBin::Bin/data/shadowed";
  push @INC, "$base_dir/b/lib";
  my @old_INC = @INC;
  local %INC = %INC;
  local @INC = @INC;
  local $FindBin::RealBin = "$base_dir/a/bin";
  local $FindLib::max_scan_iterations = 1;
  local $Module::To::Find::magic = undef;

  lives_ok {
    FindLib::findlib('Module::To::Find');
  } "findlib() does not die if the module can be found";

  is(
    $INC{'Module/To/Find.pm'},
    "$base_dir/b/lib/Module/To/Find.pm",
    "findlib() finds the module in dir in the original \@INC (and does not seek " .
    "upwards)"
  );

  cmp_deeply(
    \@INC,
    \@old_INC,
    "\@INC is not changed if the module can be found using the original \@INC"
  );

  is(
    $Module::To::Find::magic,
    'FindLib - b/lib',
    "findlib() loads the right module indeed"
  );
}

done_testing;
