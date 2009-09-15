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
  my %bin_path_to_inc = (
    '0-level/bin' => '0-level/lib',
    '1-level/a/bin' => '1-level/lib',
    '2-level/a/b/bin' => '2-level/lib',
    '3-level/a/b/c/bin' => '3-level/lib',
  );

  while (my ($bin_path, $expected_inc) =  each %bin_path_to_inc) {
    local $Module::To::Find::magic = undef;
    local @Module::To::Find::seenINC = ();

    my @newINC;
    my %newINC;

    {
      local @INC = @INC;
      local %INC = %INC;
      local $FindBin::RealBin = data_dir($bin_path);

      lives_ok {
        lib::find::find_lib('Module::To::Find');
      } "find_lib() does not die if the module can be found ('$bin_path' => '$expected_inc')";

      @newINC = @INC;
      %newINC = %INC;
    }

    is(
      file($newINC{'Module/To/Find.pm'}),
      data_file("$expected_inc/Module/To/Find.pm"),
      "find_lib() finds the right dir ('$bin_path' => '$expected_inc')"
    );

    cmp_deeply(
      \@newINC,
      [data_dir($expected_inc), @INC],
      "only the right libdir is added to the beginning of \@INC and no other changes"
    );

    cmp_deeply(
      \@Module::To::Find::seenINC,
      [data_dir($expected_inc), @INC],
      "the module sees the original \@INC with only the right libdir prepended to it but no other changes"
    );

    is(
      $Module::To::Find::magic,
      'lib::find',
      "find_lib() loads the right module"
    );
  }

  while (my ($bin_path, $expected_inc) =  each %bin_path_to_inc) {
    local $Module::To::Find::magic = undef;
    local @Module::To::Find::seenINC = ();

    my @newINC;
    my %newINC;

    {
      local @INC = @INC;
      local %INC = %INC;
      local $FindBin::RealBin = data_dir($bin_path);

      lives_ok {
        eval "use lib::find 'Module::To::Find'"; die if $@ ne "";
      } "\"use lib::find 'Module::To::Find'\" does not die if the module can " .
        "be found ('$bin_path' => '$expected_inc')";

      @newINC = @INC;
      %newINC = %INC;
    }

    is(
      file($newINC{'Module/To/Find.pm'}),
      data_file("$expected_inc/Module/To/Find.pm"),
      "\"use lib::find 'Module::To::Find'\" finds the right dir ('$bin_path' => '$expected_inc')"
    );

    cmp_deeply(
      \@newINC,
      [data_dir($expected_inc), @INC],
      "only the right libdir is added to the beginning of \@INC and no other changes"
    );

    cmp_deeply(
      \@Module::To::Find::seenINC,
      [data_dir($expected_inc), @INC],
      "the module sees the original \@INC with only the right libdir prepended to it but no other changes"
    );

    is(
      $Module::To::Find::magic,
      'lib::find',
      "\"use lib::find 'Module::To::Find'\" loads the right module"
    );
  }
}

done_testing;
