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
  local $lib::find::max_scan_iterations = 3;

  my $module_file = data_file("lib/Module/To/Find.pm");
  lives_and {
    warnings_exist {
      local @INC = @INC;
      local %INC = %INC;
      local $FindBin::RealBin = data_dir("a/b/bin");
      local $ENV{LIB_FIND_TRACE} = 1;

      lib::find::find_lib('Module::To::Find');
    } qr/^lib::find: found 'Module::To::Find' at '\Q$module_file\E' \(prepended to \@INC\)$/
  } "find_lib() emits the right warning when LIB_FIND_TRACE = 1";
}

{
  local $lib::find::max_scan_iterations = 3;

  my $libdir_candidates = join(", ",
    map { "'$_'" }
      data_dir("a/b/lib"),
      data_dir("a/lib"),
      data_dir("lib"),
  );
  my $module_file = data_file("lib/Module/To/Find.pm");
  lives_and {
    warnings_exist {
      local @INC = @INC;
      local %INC = %INC;
      local $FindBin::RealBin = data_dir("a/b/bin");
      local $ENV{LIB_FIND_TRACE} = 2;

      lib::find::find_lib('Module::To::Find');
    } [
        qr/^lib::find: libdir candidates for 'Module::To::Find': \Q$libdir_candidates\E$/,
        qr/^lib::find: found 'Module::To::Find' at '\Q$module_file\E' \(prepended to \@INC\)$/,
      ]
  } "find_lib() emits the right warnings when LIB_FIND_TRACE = 2";
}

done_testing;
