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
  local $Module::To::Find::magic = undef;
  local $lib::find::max_scan_iterations = 4;

  my @newINC;
  my %newINC;

  {
    local @INC = @INC;
    local %INC = %INC;
    local $FindBin::RealBin = data_dir("a/b/c/bin");

    lives_ok {
      lib::find::find_lib('Module::To::Find');
    } "find_lib() does not die if the module can be found";

    @newINC = @INC;
    %newINC = %INC;
  }

  is(
    $newINC{'Module/To/Find.pm'},
    data_file("a/b/lib/Module/To/Find.pm"),
    "find_lib() finds the module in the deepest dir when there are alternatives"
  );

  is(
    $Module::To::Find::magic,
    'lib::find - a/b/lib',
    "find_lib() loads the right module indeed"
  );
}

done_testing;
