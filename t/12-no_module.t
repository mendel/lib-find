#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;

use Test::Most;

use lib::find ();

{
  my $base_dir = "$FindBin::Bin/data/no_module";

  local $lib::find::max_scan_iterations = 4;

  my @newINC;
  my %newINC;

  {
    local @INC = @INC;
    local %INC = %INC;
    local $FindBin::RealBin = "$base_dir/a/b/c/d/bin";

    throws_ok {
      lib::find::find_lib('Module::To::Find');
    } qr/^Module 'Module::To::Find' not found when scanning upwards from '\Q$FindBin::RealBin\E'/,
      "find_lib() dies with the proper error message if the module cannot be found";

    @newINC = @INC;
    %newINC = %INC;
  }

  cmp_deeply(
    \@newINC,
    \@INC,
    "find_lib() does not touch \@INC if the module cannot be found"
  );
}

done_testing;
