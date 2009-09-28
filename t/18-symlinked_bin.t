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


{
  SKIP: {
    skip "Needs symbolic link support for these tests", 2
      unless
          try_to_make_symlink
            data_dir("a/real_bin"),
            data_dir("b/bin");

    local $lib::find::max_scan_iterations = 2;

    my @newINC;
    my %newINC;

    {
      local @INC = @INC;
      local %INC = %INC;
      local $FindBin::Bin = data_dir("b/bin");

      lives_ok {
        lib::find::find_lib('Module::To::Find');
      } "find_lib() does not die if the bin dir is a symlink";

      @newINC = @INC;
      %newINC = %INC;
    }

    is(
      file($newINC{'Module/To/Find.pm'}),
      data_file("b/lib/Module/To/Find.pm"),
      "find_lib() starts the scanning from the symlink not the actual dir where " .
      "it points to"
    );
  }
}

done_testing;
