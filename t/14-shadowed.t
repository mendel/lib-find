#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;

use Test::Most;

use FindLib ();

{
  my $base_dir = "$FindBin::Bin/data/shadowed";

  local @INC = ("$base_dir/b/lib", @INC);
  local $Module::To::Find::magic = undef;
  local $FindLib::max_scan_iterations = 1;

  my @newINC;
  my %newINC;

  {
    local @INC = @INC;
    local %INC = %INC;
    local $FindBin::RealBin = "$base_dir/a/bin";

    lives_ok {
      FindLib::find_lib('Module::To::Find');
    } "find_lib() does not die if the module can be found";

    @newINC = @INC;
    %newINC = %INC;
  }

  is(
    $newINC{'Module/To/Find.pm'},
    "$base_dir/b/lib/Module/To/Find.pm",
    "find_lib() finds the module in dir in the original \@INC (and does not seek " .
    "upwards)"
  );

  is(
    $Module::To::Find::magic,
    'FindLib - b/lib',
    "find_lib() loads the right module indeed"
  );

  cmp_deeply(
    \@newINC,
    \@INC,
    "\@INC is not changed if the module can be found using the original \@INC"
  );
}

done_testing;
