#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;

use Test::Most;

use FindLib ();

{
  my $base_dir = "$FindBin::Bin/data/no_search/find_lib";

  local @INC = ("$base_dir/lib", @INC);
  local $Module::To::Load::lib_dir = undef;

  my @newINC;
  my %newINC;

  {
    local @INC = @INC;
    local %INC = %INC;
    local $FindBin::RealBin = "$base_dir/bin";

    lives_ok {
      eval "use Module::To::Load"; die if $@ ne "";
    } "\"use FindLib (); FindLib::find_lib();\" does not die";

    @newINC = @INC;
    %newINC = %INC;

    is(
      $FindLib::lib{'Module::To::Load'},
      "$base_dir/lib",
      "\"use FindLib (); FindLib::find_lib();\" sets up the \%FindLib::lib slot with the " .
      "right path"
    );

    is(
      $Module::To::Load::lib_dir,
      "$base_dir/lib",
      "\"use FindLib (); FindLib::find_lib();\" sets up the \%FindLib::lib slot to the " .
      "right path during the require"
    );
  }

  cmp_deeply(
    \@newINC,
    \@INC,
    "\"use FindLib (); FindLib::find_lib();\" does not touch \@INC"
  );
}

{
  my $base_dir = "$FindBin::Bin/data/no_search/use";

  local @INC = ("$base_dir/lib", @INC);
  local $Module::To::Load::lib_dir = undef;

  my @newINC;
  my %newINC;

  {
    local @INC = @INC;
    local %INC = %INC;
    local $FindBin::RealBin = "$base_dir/bin";

    lives_ok {
      eval "use Module::To::Load"; die if $@ ne "";
    } "\"use FindLib;\" does not die";

    @newINC = @INC;
    %newINC = %INC;

    is(
      $FindLib::lib{'Module::To::Load'},
      "$base_dir/lib",
      "\"use FindLib;\" sets up the \%FindLib::lib slot with the right path"
    );

    is(
      $Module::To::Load::lib_dir,
      "$base_dir/lib",
      "\"use FindLib;\" sets up the \%FindLib::lib slot to the right path " .
      "during the require"
    );
  }

  cmp_deeply(
    \@newINC,
    \@INC,
    "\"use FindLib;\" does not touch \@INC"
  );
}

done_testing;
