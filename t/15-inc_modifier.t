#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;

use Test::Most;

use FindLib ();

{
  my $base_dir = "$FindBin::Bin/data/inc_modifier";

  my @newINC;
  my %newINC;

  {
    local @INC = @INC;
    local %INC = %INC;
    local $FindBin::RealBin = "$base_dir/bin";

    lives_ok {
      FindLib::findlib('Module::To::Find');
    } "findlib() does not die if the module can be found";

    @newINC = @INC;
    %newINC = %INC;
  }

  eq_or_diff(
    \@newINC,
    ['FindLibPre', "$base_dir/lib", @INC, 'FindLibPost'],
    "the modifications to \@INC by the loaded module are kept"
  );
}

done_testing;
