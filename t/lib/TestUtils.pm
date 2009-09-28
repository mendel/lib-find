package TestUtils;

use strict;
use warnings;

use FindBin;
use Path::Class;

use base qw(Exporter);

our @EXPORT = qw(
  &data_dir
  &data_file
  &try_to_make_symlink
  &try_to_make_fifo
);

# we have to copy the FindBin variables as some tests locally overwrite them
our $FindBin_Bin = $FindBin::Bin;
our $FindBin_Script = $FindBin::Script;

#FIXME dirty hack - remove before uploading to CPAN
# monkey-patch internals of Path::Class till my patch gets included
{
  if (!Path::Class::Dir->can('as_native')) {
    no warnings 'redefine';

    my $_spec_class = \&Path::Class::Entity::_spec_class;
    *Path::Class::Entity::_spec_class = sub {
      my ($class, $type) = @_;

      return undef if $type eq 'NATIVE';

      $_spec_class->(@_);
    };

    *Path::Class::Entity::as_native = *Path::Class::Entity::as_native = sub {
      my $self = shift;

      return $self->as_foreign('NATIVE');
    };
  }
}

sub _test_name
{
  my ($test_name) = ($FindBin_Script =~ /^\d+[_-](.*)\.t$/);

  return $test_name;
}

sub data_dir
{
  my ($subdir) = @_;

  $subdir = "" if !defined $subdir;

  my $test_name = _test_name();

  my $bin_dir = dir($FindBin_Bin);

  return dir($bin_dir->volume,
    $bin_dir->as_foreign('Unix')
      ->subdir("data/$test_name/$subdir")->as_native
  )->stringify;
}

sub data_file
{
  my ($subdirs_and_filename) = @_;

  $subdirs_and_filename = "" if !defined $subdirs_and_filename;

  my $test_name = _test_name();

  my $bin_dir = dir($FindBin_Bin);

  return dir($bin_dir->volume,
    $bin_dir->as_foreign('Unix')
      ->file("data/$test_name/$subdirs_and_filename")->as_native
  )->stringify;
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

1;
