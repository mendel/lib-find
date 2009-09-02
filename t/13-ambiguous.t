#!/usr/bin/perl

use strict;
use warnings;

use FindBin;

use Test::Most;

use FindLib ();

{
  my $base_dir = "$FindBin::Bin/data/ambiguous";
  local %INC = %INC;
  local @INC = @INC;
  local $FindBin::RealBin = "$base_dir/a/b/c/bin";
  local $FindLib::max_scan_iterations = 4;
  local $Module::To::Find::magic = undef;

  lives_ok {
    FindLib::findlib('Module::To::Find');
  } "findlib() does not die if the module can be found";

  is(
    $INC{'Module/To/Find.pm'},
    "$base_dir/a/b/lib/Module/To/Find.pm",
    "findlib() finds the module in the deepest dir when there are alternatives"
  );

  is(
    $Module::To::Find::magic,
    'FindLib - a/b/lib',
    "findlib() loads the right module indeed"
  );
}

done_testing;
