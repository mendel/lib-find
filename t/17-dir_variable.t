#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;

use FindBin;
use Path::Class;
use lib dir($FindBin::Bin)->subdir('lib')->stringify;

use TestUtils;

use List::MoreUtils qw(zip);
use Path::Class;

use lib::find ();

{
  lives_and {
    ok(exists $lib::find::dir{'Test::Most'});
  } "exists \$lib::find::dir{'Test::Most'} is true";

  lives_and {
    is(
      $lib::find::dir{'Test::Most'},
      dir(lib::find::libdir_path('Test::Most'))
    );
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
    is(
      $lib::find::dir,
      dir(lib::find::libdir_path('Test::Most'))
    );
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
      path => "some/path/to/Foo.pm",
      libdir => "some/path/to",
    },
    {
      desc => "1-element module name, 1 dirs deep libdir",
      module => 'Foo',
      path => "to/Foo.pm",
      libdir => "to",
    },
    {
      desc => "1-element module name, 0 dirs deep libdir",
      module => 'Foo',
      path => "Foo.pm",
      libdir => "",
    },
    {
      desc => "2-element module name, 3 dirs deep libdir",
      module => 'Foo::Bar',
      path => "some/path/to/Foo/Bar.pm",
      libdir => "some/path/to",
    },
    {
      desc => "2-element module name, 1 dirs deep libdir",
      module => 'Foo::Bar',
      path => "to/Foo/Bar.pm",
      libdir => "to",
    },
    {
      desc => "2-element module name, 0 dirs deep libdir",
      module => 'Foo::Bar',
      path => "Foo/Bar.pm",
      libdir => "",
    },
    {
      desc => "1-element module name, inconsistent \%INC",
      module => 'Foo',
      path => "some/path/to/Bar.pm",
      throws => q/^Inconsistent %INC: '__MODULE__' => '__PATH__'/,
    },
    {
      desc => "2-element module name, inconsistent \%INC",
      module => 'Foo::Bar',
      path => "some/path/to/Foo/Quux.pm",
      throws => q/^Inconsistent %INC: '__MODULE__' => '__PATH__'/,
    },
  );

  foreach my $test (@tests) {
    my $path = data_file("libdir_path/$test->{path}");

    (my $inc_key = "$test->{module}.pm") =~ s{::}{/}g;

    $test->{libdir} ||= "";
    my $expected_libdir = data_dir("libdir_path/$test->{libdir}");

    my $test_sub = sub {
      local $INC{$inc_key} = $path;

      is(
        dir(lib::find::libdir_path($test->{module})),
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
  my $libdir;
  {
    local $INC{'Foo/Bar.pm'} =
      file(data_file("libdir_path/some/path/to/Foo/Bar.pm"))->relative
        ->stringify;

    $libdir = dir(lib::find::libdir_path('Foo::Bar'));
  }

  is(
    $libdir,
    dir($libdir)->absolute,
    "libdir_path() returns an absolute path"
  );
}

{
  {
    local @INC = @INC;
    local %INC = %INC;
    local $FindBin::RealBin = data_dir("hash/bin");
    local $Module::To::Find::lib_dir = undef;

    lives_ok {
      lib::find::find_lib('Module::To::Find');
    } "find_lib() does not die if the module can be found";

    is(
      $lib::find::dir{'Module::To::Find'},
      data_dir("hash/lib"),
      "find_lib() sets up the \%lib::find::dir slot with the right path"
    );

    is(
      $Module::To::Find::lib_dir,
      data_dir("hash/lib"),
      "the \%lib::find::dir slot is set to the right path during the require"
    );
  }
}

{
  {
    local @INC = @INC;
    local %INC = %INC;
    local $FindBin::RealBin = data_dir("scalar/bin");
    local $Module::To::Find::lib_dir = undef;

    lives_ok {
      lib::find::find_lib('Module::To::Find');
    } "find_lib() does not die if the module can be found";

    is(
      $Module::To::Find::lib_dir,
      data_dir("scalar/lib"),
      "the \$lib::find::dir variable is set to the right path during the require"
    );
  }
}

done_testing;
