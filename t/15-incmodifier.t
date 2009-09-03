#!/usr/bin/perl

use strict;
use warnings;

use FindBin;

use Test::Most;

use FindLib ();

{
  my $base_dir = "$FindBin::Bin/data/incmodifier";
  my @old_INC = @INC;
  local %INC = %INC;
  local @INC = @INC;
  local $FindBin::RealBin = "$base_dir/bin";

  lives_ok {
    FindLib::findlib('Module::To::Find');
  } "findlib() does not die if the module can be found";

  eq_or_diff(
    \@INC,
    ['FindLibPre', "$base_dir/lib", @old_INC, 'FindLibPost'],
    "the modifications to \@INC by the loaded module are kept"
  );
}

done_testing;
