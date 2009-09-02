#!/usr/bin/perl

use strict;
use warnings;

use FindBin;

use Test::Most;

use FindLib ();

{
  my $base_dir = "$FindBin::Bin/data/shadowed";
  local %INC = %INC;
  local @INC = @INC;
  local $FindBin::RealBin = "$base_dir/bin";
  local $Math::BigInt::magic = undef;

  delete $INC{'Math/BigInt.pm'};  # just in case..

  lives_ok {
    FindLib::findlib('Math::BigInt');
  } "findlib() does not die if the module can be found";

  is(
    $INC{'Math/BigInt.pm'},
    "$base_dir/lib/Math/BigInt.pm",
    "findlib() finds the shadowing module in the local dirs (and not the system " .
    "module)"
  );

  is(
    $Math::BigInt::magic,
    'FindLib',
    "findlib() loads the right module indeed"
  );
}

done_testing;
