#!/usr/bin/perl

use strict;
use warnings;

use FindBin;

use Test::Most;

use FindLib ();

{
  my $base_dir = "$FindBin::Bin/data/no_module";

  local $FindLib::max_scan_iterations = 4;

  my @newINC;
  my %newINC;

  {
    local @INC = @INC;
    local %INC = %INC;
    local $FindBin::RealBin = "$base_dir/a/b/c/d/bin";

    throws_ok {
      FindLib::findlib('Module::To::Find');
    } qr/^Module 'Module::To::Find' not found when scanning upwards from '\Q$FindBin::RealBin\E'/,
      "findlib() dies with the proper error message if the module cannot be found";

    @newINC = @INC;
    %newINC = %INC;
  }

  cmp_deeply(
    \@newINC,
    \@INC,
    "findlib() does not touch \@INC if the module cannot be found"
  );
}

done_testing;
