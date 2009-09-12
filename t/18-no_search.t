#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;

use Test::Most;

use lib::find ();

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
    } "\"use lib::find (); lib::find::find_lib();\" does not die";

    @newINC = @INC;
    %newINC = %INC;

    is(
      $lib::find::dir{'Module::To::Load'},
      "$base_dir/lib",
      "\"use lib::find (); lib::find::find_lib();\" sets up the \%lib::find::dir slot with the " .
      "right path"
    );

    is(
      $Module::To::Load::lib_dir,
      "$base_dir/lib",
      "\"use lib::find (); lib::find::find_lib();\" sets up the \%lib::find::dir slot to the " .
      "right path during the require"
    );
  }

  cmp_deeply(
    \@newINC,
    \@INC,
    "\"use lib::find (); lib::find::find_lib();\" does not touch \@INC"
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
    } "\"use lib::find;\" does not die";

    @newINC = @INC;
    %newINC = %INC;

    is(
      $lib::find::dir{'Module::To::Load'},
      "$base_dir/lib",
      "\"use lib::find;\" sets up the \%lib::find::dir slot with the right path"
    );

    is(
      $Module::To::Load::lib_dir,
      "$base_dir/lib",
      "\"use lib::find;\" sets up the \%lib::find::dir slot to the right path " .
      "during the require"
    );
  }

  cmp_deeply(
    \@newINC,
    \@INC,
    "\"use lib::find;\" does not touch \@INC"
  );
}

done_testing;
