#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;

use FindBin;
use Path::Class;
use lib dir($FindBin::Bin)->subdir('lib')->stringify;

use TestUtils;

use List::MoreUtils qw(none);

use lib::find ();


# Override L<perlfunc/require> so that we can see in C<@libdirs_tried> what
# libdirs find_lib() tried to load modules from.
our @libdirs_tried;
{
  no warnings 'redefine', 'once';
  *CORE::GLOBAL::require = sub {
    push @libdirs_tried, $INC[0];

    CORE::require $_[0];
  };
}

#
# my $success = try_to_make_symlink($old_path, $new_path);
#
# Creates a symlink if symlinks are supported on the platform.
#
# Returns the return value of L<perlfunc/symlink> or false if symbolic links are
# not supported on the platform.
#
sub try_to_make_symlink($$)
{
  my ($old_path, $new_path) = @_;

  # test for symlink support per L<perlfunc/symlink>
  return 0 unless eval { symlink "", ""; 1 };

  if (-l $new_path) {
    unlink $new_path;
  }

  symlink $old_path, $new_path
    or die "Cannot symlink '$old_path' to '$new_path': $!";
}

#
# my $success = try_to_make_fifo($path);
#
# Creates a named pipe (FIFO) if named pipes are supported on the platform.
#
# Returns the return value of L<POSIX/mkfifo> or false if named pipes are not
# supported on the platform.
#
sub try_to_make_fifo($)
{
  my ($path) = @_;

  return 0 unless
    eval { require POSIX } && $@ eq "" &&
    eval { POSIX::mkfifo("", 0777); 1 } && $@ eq "";

  if (-p $path) {
    unlink $path;
  }

  return POSIX::mkfifo($path, 0777)
    or die "Cannot create named pipe (FIFO) '$path': $!";
}


{
  local $lib::find::max_scan_iterations = 2;

  my @newINC;
  my %newINC;
  my @new_libdirs_tried;

  {
    local @INC = @INC;
    local %INC = %INC;
    local @libdirs_tried = @libdirs_tried;
    local $FindBin::RealBin = data_dir("file/a/bin");

    lives_ok {
      lib::find::find_lib('Module::To::Find');
    } "find_lib() does not die if the deepest libdir candidate is a plain file";

    @newINC = @INC;
    %newINC = %INC;
    @new_libdirs_tried = @libdirs_tried;
  }

  is(
    file($newINC{'Module/To/Find.pm'}),
    data_file("file/lib/Module/To/Find.pm"),
    "find_lib() skips the deepest libdir candidate if it's a plain file"
  );

  ok(
    (none { $_ eq data_dir("file/a/lib") } @new_libdirs_tried),
    "find_lib() does not attempt to load the module from the libdir candidate if " .
    "it's a plain file"
  );
}

{
  SKIP: {
    skip "Needs symbolic link support for these tests", 2
      unless
          try_to_make_symlink
            data_dir("symlink_to_dir/a/real_lib"),
            data_dir("symlink_to_dir/a/lib");

    local $lib::find::max_scan_iterations = 2;

    my @newINC;
    my %newINC;
    my @new_libdirs_tried;

    {
      local @INC = @INC;
      local %INC = %INC;
      local @libdirs_tried = @libdirs_tried;
      local $FindBin::RealBin = data_dir("symlink_to_dir/a/bin");

      lives_ok {
        lib::find::find_lib('Module::To::Find');
      } "find_lib() does not die if the deepest libdir candidate is a symlink " .
        "to a dir";

      @newINC = @INC;
      %newINC = %INC;
      @new_libdirs_tried = @libdirs_tried;
    }

    is(
      file($newINC{'Module/To/Find.pm'}),
      data_file("symlink_to_dir/a/lib/Module/To/Find.pm"),
      "find_lib() chooses the deepest libdir candidate if it's a symlink to a dir"
    );
  }
}

{
  SKIP: {
    skip "Needs symbolic link support for these tests", 3
      unless
          try_to_make_symlink
            data_dir("symlink_to_file/a/real_lib"),
            data_dir("symlink_to_file/a/lib");

    local $lib::find::max_scan_iterations = 2;

    my @newINC;
    my %newINC;
    my @new_libdirs_tried;

    {
      local @INC = @INC;
      local %INC = %INC;
      local @libdirs_tried = @libdirs_tried;
      local $FindBin::RealBin = data_dir("symlink_to_file/a/bin");

      lives_ok {
        lib::find::find_lib('Module::To::Find');
      } "find_lib() does not die if the deepest libdir candidate is a symlink " .
        "to a plain file";

      @newINC = @INC;
      %newINC = %INC;
      @new_libdirs_tried = @libdirs_tried;
    }

    is(
      file($newINC{'Module/To/Find.pm'}),
      data_file("symlink_to_file/lib/Module/To/Find.pm"),
      "find_lib() skips the deepest libdir candidate if it's a symlink to a " .
      "plain file"
    );

    ok(
      (none { $_ eq data_dir("symlink_to_file/a/lib") } @new_libdirs_tried),
      "find_lib() does not attempt to load the module from the libdir candidate if " .
      "it's a symlink to a plain file"
    );
  }
}

{
  SKIP: {
    skip "Needs named pipe (FIFO) support for these tests", 3 unless
      try_to_make_fifo(data_file("fifo/a/lib"));

    local $lib::find::max_scan_iterations = 2;

    my @newINC;
    my %newINC;
    my @new_libdirs_tried;

    {
      local @INC = @INC;
      local %INC = %INC;
      local @libdirs_tried = @libdirs_tried;
      local $FindBin::RealBin = data_dir("fifo/a/bin");

      lives_ok {
        lib::find::find_lib('Module::To::Find');
      } "find_lib() does not die if the deepest libdir candidate is a named " .
        "pipe (FIFO)";

      @newINC = @INC;
      %newINC = %INC;
      @new_libdirs_tried = @libdirs_tried;
    }

    is(
      file($newINC{'Module/To/Find.pm'}),
      data_file("fifo/lib/Module/To/Find.pm"),
      "find_lib() skips the deepest libdir candidate if it's a named pipe (FIFO)"
    );

    ok(
      (none { $_ eq data_dir("fifo/a/lib") } @new_libdirs_tried),
      "find_lib() does not attempt to load the module from the libdir candidate if " .
      "it's a named pipe (FIFO)"
    );
  }
}

done_testing;
