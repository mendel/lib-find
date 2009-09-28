#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;

use FindBin;
use Path::Class;
use lib dir($FindBin::Bin)->subdir('lib')->stringify;

use TestUtils;

use List::MoreUtils qw(none);

use lib::find ();

{
  SKIP: {
    skip "Needs symbolic link support for these tests", 2
      unless
          try_to_make_symlink
            data_dir("a/real_bin"),
            data_dir("b/bin");

    local $lib::find::max_scan_iterations = 2;

    my @newINC;
    my %newINC;

    {
      local @INC = @INC;
      local %INC = %INC;
      local $FindBin::Bin = data_dir("b/bin");

      lives_ok {
        lib::find::find_lib('Module::To::Find');
      } "find_lib() does not die if the bin dir is a symlink";

      @newINC = @INC;
      %newINC = %INC;
    }

    is(
      file($newINC{'Module/To/Find.pm'}),
      data_file("b/lib/Module/To/Find.pm"),
      "find_lib() starts the scanning from the symlink not the actual dir where " .
      "it points to"
    );
  }
}

done_testing;
