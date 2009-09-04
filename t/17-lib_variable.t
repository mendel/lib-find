#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use File::Spec;

use Test::Most;

use FindLib ();

{
  my @tests = (
    {
      desc => "1-element module name, 3 dirs deep libdir",
      module => 'Foo',
      path => [qw(some path to Foo.pm)],
      libdir => [qw(some path to)],
    },
    {
      desc => "1-element module name, 1 dirs deep libdir",
      module => 'Foo',
      path => [qw(to Foo.pm)],
      libdir => [qw(to)],
    },
    {
      desc => "1-element module name, 0 dirs deep libdir",
      module => 'Foo',
      path => [qw(Foo.pm)],
      libdir => [qw()],
    },
    {
      desc => "2-element module name, 3 dirs deep libdir",
      module => 'Foo::Bar',
      path => [qw(some path to Foo Bar.pm)],
      libdir => [qw(some path to)],
    },
    {
      desc => "2-element module name, 1 dirs deep libdir",
      module => 'Foo::Bar',
      path => [qw(to Foo Bar.pm)],
      libdir => [qw(to)],
    },
    {
      desc => "2-element module name, 0 dirs deep libdir",
      module => 'Foo::Bar',
      path => [qw(Foo Bar.pm)],
      libdir => [qw()],
    },
    {
      desc => "1-element module name, inconsistent \%INC",
      module => 'Foo',
      path => [qw(some path to Bar.pm)],
      throws => q/^Inconsistent %INC: '__MODULE__' => '__PATH__'/,
    },
    {
      desc => "2-element module name, inconsistent \%INC",
      module => 'Foo::Bar',
      path => [qw(some path to Foo Quux.pm)],
      throws => q/^Inconsistent %INC: '__MODULE__' => '__PATH__'/,
    },
  );

  foreach my $test (@tests) {
    my @path_dirs = @{$test->{path} || []};
    my $path_filename = pop @path_dirs;
    my $path = File::Spec->catpath(
      '',
      File::Spec->catdir(File::Spec->rootdir, @path_dirs),
      $path_filename
    );

    my $expected_libdir =
        File::Spec->catpath(
          '',
          File::Spec->catdir(File::Spec->rootdir, @{$test->{libdir} || []}),
          ''
        );

    my $test_sub = sub {
      local $Test::Builder::Level = $Test::Builder::Level + 1;

      is(
        FindLib::_libdir_path($path, $test->{module}),
        $expected_libdir,
        "$test->{desc} - _libdir_path() returns the right dir"
      );
    };

    if ($test->{throws}) {
      my $re = $test->{throws};
      $re =~ s/__MODULE__/\Q$test->{module}\E/g;
      $re =~ s/__PATH__/\Q$path\E/g;
      my $exception = qr/$re/;

      throws_ok {
        $test_sub->()
      } $exception,
        "$test->{desc} - throws the expected exception";
    } else {
      lives_ok {
        $test_sub->()
      } "$test->{desc} - does not die";
    }
  }
}

{
  my $base_dir = "$FindBin::Bin/data/simple/0-level";

  {
    local @INC = @INC;
    local %INC = %INC;
    local $FindBin::RealBin = "$base_dir/bin";

    lives_ok {
      FindLib::findlib('Module::To::Find');
    } "findlib() does not die if the module can be found";
  }

  is(
    $FindLib::lib{'Module::To::Find'},
    "$base_dir/lib",
    "findlib() sets up the \%FindLib::lib slot with the right path"
  );
}

done_testing;
