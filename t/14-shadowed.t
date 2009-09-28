#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;

use FindBin;
use Path::Class;
use lib dir($FindBin::Bin)->subdir('lib')->stringify;

use TestUtils;

use lib::find ();

{
  local @INC = (data_dir("b/lib"), @INC);
  local $Module::To::Find::magic = undef;
  local $lib::find::max_scan_iterations = 1;

  my @newINC;
  my %newINC;

  {
    local @INC = @INC;
    local %INC = %INC;
    local $FindBin::Bin = data_dir("a/bin");

    lives_ok {
      lib::find::find_lib('Module::To::Find');
    } "find_lib() does not die if the module can be found";

    @newINC = @INC;
    %newINC = %INC;
  }

  is(
    file($newINC{'Module/To/Find.pm'}),
    data_file("b/lib/Module/To/Find.pm"),
    "find_lib() finds the module in dir in the original \@INC (and does not seek " .
    "upwards)"
  );

  is(
    $Module::To::Find::magic,
    'lib::find - b/lib',
    "find_lib() loads the right module indeed"
  );

  cmp_deeply(
    \@newINC,
    \@INC,
    "\@INC is not changed if the module can be found using the original \@INC"
  );
}

done_testing;
