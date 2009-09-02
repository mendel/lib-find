#!/usr/bin/perl

use strict;
use warnings;

use FindBin;

use Test::Most;

use FindLib ();

{
  my %bin_path_to_inc = (
    '0-level/bin' => '0-level/lib',
    '1-level/a/bin' => '1-level/lib',
    '2-level/a/b/bin' => '2-level/lib',
    '3-level/a/b/c/bin' => '3-level/lib',
  );

  while (my ($bin_path, $expected_inc) =  each %bin_path_to_inc) {
    my $base_dir = "$FindBin::Bin/data/simple";
    local %INC = %INC;
    local @INC = @INC;
    local $FindBin::RealBin = "$base_dir/$bin_path";
    local $Module::To::Find::magic = undef;

    lives_ok {
      FindLib::findlib('Module::To::Find');
    } "findlib() does not die if the module can be found ('$bin_path' => '$expected_inc')";

    is(
      $INC{'Module/To/Find.pm'},
      "$base_dir/$expected_inc/Module/To/Find.pm",
      "findlib() finds the right dir ('$bin_path' => '$expected_inc')"
    );

    is(
      $Module::To::Find::magic,
      'FindLib',
      "findlib() loads the right module"
    );
  }

  while (my ($bin_path, $expected_inc) =  each %bin_path_to_inc) {
    my $base_dir = "$FindBin::Bin/data/simple";
    local %INC = %INC;
    local @INC = @INC;
    local $FindBin::RealBin = "$base_dir/$bin_path";
    local $Module::To::Find::magic = undef;

    eval "use FindLib 'Module::To::Find'";
    is(
      $@,
      "",
      "\"use FindLib 'Module::To::Find'\" does not die if the module can " .
      "be found ('$bin_path' => '$expected_inc')"
    );

    is(
      $INC{'Module/To/Find.pm'},
      "$base_dir/$expected_inc/Module/To/Find.pm",
      "\"use FindLib 'Module::To::Find'\" finds the right dir ('$bin_path' => '$expected_inc')"
    );

    is(
      $Module::To::Find::magic,
      'FindLib',
      "\"use FindLib 'Module::To::Find'\" loads the right module"
    );
  }
}

done_testing;
