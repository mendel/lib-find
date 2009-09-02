#!/usr/bin/perl

use strict;
use warnings;

use FindBin;

use Test::Most;

use FindLib ();

{
  my @orig_INC = @INC;
  my $base_dir = "$FindBin::Bin/data/nolibdirs";
  local %INC = %INC;
  local @INC = @INC;
  local $FindBin::RealBin = "$base_dir/a/b/c/d/bin";
  local $FindLib::max_scan_iterations = 4;

  throws_ok {
    FindLib::findlib('Module::To::Find');
  } qr/^No libdir candidates \(.*\) found when scanning upwards from '\Q$FindBin::RealBin\E'/,
    "findlib() dies with the proper error message if no libdir candidates found";

  cmp_deeply(
    \@INC,
    \@orig_INC,
    "findlib() does not touch \@INC if no libdir candidates found"
  );
}

done_testing;
