#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use File::Spec;
use List::MoreUtils qw(zip);

use Test::Most;

use lib::find ();

{
  lives_and {
    ok(exists $lib::find::dir{'Test::Most'});
  } "exists \$lib::find::dir{'Test::Most'} is true";

  lives_and {
    is($lib::find::dir{'Test::Most'}, lib::find::libdir_path('Test::Most'));
  } "reading \$lib::find::dir{'Test::Most'} returns the right value";

  {
    my @keys;
    lives_ok {
      @keys = keys %lib::find::dir;
    } "keys \%lib::find::dir does not die";

    my @values;
    lives_ok {
      @values = values %lib::find::dir;
    } "values \%lib::find::dir does not die";

    is(
      scalar @keys,
      scalar keys %INC,
      "\%lib::find::dir has the same number of keys as \%INC"
    );

    eq_or_diff(
      [
        zip @keys, @values
      ],
      [
        map {
          $_ => $lib::find::dir{$_}
        } @keys
      ],
      "keys \%lib::find::dir and values \%lib::find::dir return the elements in " .
      "the same order"
    );
  }

  lives_and {
    is(scalar %lib::find::dir, scalar %INC);
  } "scalar \%lib::find::dir is the same as scalar \%INC";

  throws_ok {
    $lib::find::dir{'Test::Most'} = 'anything';
  } qr/^You cannot modify the \%lib::find::dir variable/,
  "attempt to assign to \$lib::find::dir{'Test::Most'} throws the proper exception";

  throws_ok {
    delete $lib::find::dir{'Test::Most'};
  } qr/^You cannot modify the \%lib::find::dir variable/,
  "attempt to delete \$lib::find::dir{'Test::Most'} throws the proper exception";

  throws_ok {
    %lib::find::dir = ();
  } qr/^You cannot modify the \%lib::find::dir variable/,
  "attempt to clear \%lib::find::dir throws the proper exception";

  throws_ok {
    untie %lib::find::dir;
  } qr/^You cannot modify the \%lib::find::dir variable/,
  "attempt to untie \%lib::find::dir throws the proper exception";
}

{
  lives_and {
    is($lib::find::dir, lib::find::libdir_path('Test::Most'));
  } "reading \$lib::find::dir returns the right value";

  throws_ok {
    $lib::find::dir = 'anything';
  } qr/^You cannot modify the \$lib::find::dir variable/,
  "attempt to assign to \$lib::find::dir throws the proper exception";

  throws_ok {
    untie $lib::find::dir;
  } qr/^You cannot modify the \$lib::find::dir variable/,
  "attempt to untie \$lib::find::dir throws the proper exception";
}

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

    (my $inc_key = "$test->{module}.pm") =~ s{::}{/}g;

    my $expected_libdir =
        File::Spec->catpath(
          '',
          File::Spec->catdir(File::Spec->rootdir, @{$test->{libdir} || []}),
          ''
        );

    my $test_sub = sub {
      local $Test::Builder::Level = $Test::Builder::Level + 1;
      local $INC{$inc_key} = $path;

      is(
        lib::find::libdir_path($test->{module}),
        $expected_libdir,
        "$test->{desc} - libdir_path() returns the right dir"
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
  my $base_dir = "$FindBin::Bin/data/dir_variable/hash";

  {
    local @INC = @INC;
    local %INC = %INC;
    local $FindBin::RealBin = "$base_dir/bin";
    local $Module::To::Find::lib_dir = undef;

    lives_ok {
      lib::find::find_lib('Module::To::Find');
    } "find_lib() does not die if the module can be found";

    is(
      $lib::find::dir{'Module::To::Find'},
      "$base_dir/lib",
      "find_lib() sets up the \%lib::find::dir slot with the right path"
    );

    is(
      $Module::To::Find::lib_dir,
      "$base_dir/lib",
      "the \%lib::find::dir slot is set to the right path during the require"
    );
  }
}

{
  my $base_dir = "$FindBin::Bin/data/dir_variable/scalar";

  {
    local @INC = @INC;
    local %INC = %INC;
    local $FindBin::RealBin = "$base_dir/bin";
    local $Module::To::Find::lib_dir = undef;

    lives_ok {
      lib::find::find_lib('Module::To::Find');
    } "find_lib() does not die if the module can be found";

    is(
      $Module::To::Find::lib_dir,
      "$base_dir/lib",
      "the \$lib::find::dir variable is set to the right path during the require"
    );
  }
}

done_testing;
