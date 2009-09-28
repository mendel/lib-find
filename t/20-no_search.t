#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;

use FindBin;
use Path::Class;
use lib dir($FindBin::Bin)->subdir('lib')->stringify;

use TestUtils;

use lib::find ();

{
  local $TestUtils::base_dir = "find_lib";

  local @INC = (data_dir("lib"), @INC);
  local $Module::To::Load::lib_dir = undef;

  my @newINC;
  my %newINC;

  {
    local @INC = @INC;
    local %INC = %INC;
    local $FindBin::Bin = data_dir("bin");

    lives_ok {
      eval "use Module::To::Load"; die if $@ ne "";
    } "\"use lib::find (); lib::find::find_lib(undef);\" does not die";

    @newINC = @INC;
    %newINC = %INC;

    is(
      dir($lib::find::dir{'Module::To::Load'}),
      data_dir("lib"),
      "\"use lib::find (); lib::find::find_lib(undef);\" sets up the \%lib::find::dir slot with the " .
      "right path"
    );

    is(
      dir($Module::To::Load::lib_dir),
      data_dir("lib"),
      "\"use lib::find (); lib::find::find_lib(undef);\" sets up the \%lib::find::dir slot to the " .
      "right path during the require"
    );
  }

  cmp_deeply(
    \@newINC,
    \@INC,
    "\"use lib::find (); lib::find::find_lib(undef);\" does not touch \@INC"
  );
}

{
  local $TestUtils::base_dir = "use";

  local @INC = (data_dir("lib"), @INC);
  local $Module::To::Load::lib_dir = undef;

  my @newINC;
  my %newINC;

  {
    local @INC = @INC;
    local %INC = %INC;
    local $FindBin::Bin = data_dir("bin");

    lives_ok {
      eval "use Module::To::Load"; die if $@ ne "";
    } "\"use lib::find;\" does not die";

    @newINC = @INC;
    %newINC = %INC;

    is(
      dir($lib::find::dir{'Module::To::Load'}),
      data_dir("lib"),
      "\"use lib::find;\" sets up the \%lib::find::dir slot with the right path"
    );

    is(
      dir($Module::To::Load::lib_dir),
      data_dir("lib"),
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
