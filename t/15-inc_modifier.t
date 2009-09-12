#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;

use Test::Most;

use lib::find ();

{
  my $base_dir = "$FindBin::Bin/data/inc_modifier";

  my @newINC;
  my %newINC;

  {
    local @INC = @INC;
    local %INC = %INC;
    local $FindBin::RealBin = "$base_dir/bin";

    lives_ok {
      lib::find::find_lib('Module::To::Find');
    } "find_lib() does not die if the module can be found";

    @newINC = @INC;
    %newINC = %INC;
  }

  eq_or_diff(
    \@newINC,
    ['lib::find-pre', "$base_dir/lib", @INC, 'lib::find-post'],
    "the modifications to \@INC by the loaded module are kept"
  );
}

done_testing;
