#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;

use Test::Most;

use FindLib ();

{
  my $base_dir = "$FindBin::Bin/data/ambiguous";

  local $Module::To::Find::magic = undef;
  local $FindLib::max_scan_iterations = 4;

  my @newINC;
  my %newINC;

  {
    local @INC = @INC;
    local %INC = %INC;
    local $FindBin::RealBin = "$base_dir/a/b/c/bin";

    lives_ok {
      FindLib::find_lib('Module::To::Find');
    } "find_lib() does not die if the module can be found";

    @newINC = @INC;
    %newINC = %INC;
  }

  is(
    $newINC{'Module/To/Find.pm'},
    "$base_dir/a/b/lib/Module/To/Find.pm",
    "find_lib() finds the module in the deepest dir when there are alternatives"
  );

  is(
    $Module::To::Find::magic,
    'FindLib - a/b/lib',
    "find_lib() loads the right module indeed"
  );
}

done_testing;
