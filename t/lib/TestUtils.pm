package TestUtils;

use strict;
use warnings;

use FindBin;
use Path::Class;

=head1 NAME

TestUtils - test utilities

=head1 SYNOPSIS

=head1 DESCRIPTION

Various utilities used from the tests.

=head1 EXPORT

=over

=item L</data_dir>

=item L</data_file>

=item L</try_to_make_symlink>

=item L</try_to_make_fifo>

=back

=cut

use base qw(Exporter);

our @EXPORT = qw(
  &data_dir
  &data_file
  &try_to_make_symlink
  &try_to_make_fifo
);

=head1 VARIABLES

=cut

# we have to copy the FindBin variables as some tests locally overwrite them
our $FindBin_Bin = $FindBin::Bin;
our $FindBin_Script = $FindBin::Script;

=head2 $base_dir

Used as a prefix in data_dir() and data_file().

You can localize and set it to any value you like and it saves you a lot of
code repetition:

  {
    local $TestUtils::base_dir = '1-level';

    my $dir = data_dir('foo');  # t/data/test_name/1-level/foo
  }

=cut

our $base_dir;

=head1 FUNCTIONS

=cut

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


=head2 test_name()

Returns the basename of the test file with the leading digits and
dash/underscore stripped off.

=cut

sub test_name
{
  my ($test_name) = ($FindBin_Script =~ /^\d+[_-](.*)\.t$/);

  return $test_name;
}


=head2 data_dir($subdir)

Returns a string that represents the directory under C<<
$FindBin::Bin/data/$test_name/$base_dir/$subdir >> (where C<$test_name> is the
basename of the test file (see L</test_name>), for C</$base_dir> see
L</$base_dir>).

Note that C<$subdir> (and L</$base_dir>) must be in Unix notation, while the
returned dir will be in the local path notation.

Example:

  my $dir = data_dir('foo/bar');  # t/data/test_name/foo/bar

=cut

sub data_dir
{
  my ($subdir) = @_;

  $subdir = "" if !defined $subdir;

  my $test_name = test_name();

  my $bin_dir = dir($FindBin_Bin);

  my @subdirs =
    ('data', $test_name, defined $base_dir ? ($base_dir) : (), $subdir);

  return dir($bin_dir->volume,
    $bin_dir->as_foreign('Unix')->subdir(@subdirs)->as_native
  )->stringify;
}


=head2 data_file($subdirs_and_filename)

Returns a L<Path::Class::File> object that represents the file under C<<
$FindBin::Bin/data/$test_name/$base_dir/$subdirs_and_filename >> (where
C<$test_name> is the basename of the test file (see L</test_name>), for
C</$base_dir> see L</$base_dir>).

Note that C<$subdirs_and_filename> (and L</$base_dir>) must be in Unix
notation, but the returned L<Path::Class::Dir> instance will work using the
local path conventions.

Example:

  my $file = data_file('foo/bar.pm');  # t/data/test_name/foo/bar.pm

=cut

sub data_file
{
  my ($subdirs_and_filename) = @_;

  $subdirs_and_filename = "" if !defined $subdirs_and_filename;

  my $test_name = test_name();

  my $bin_dir = dir($FindBin_Bin);

  my @subdirs_and_filename =
    ('data', $test_name, defined $base_dir ? ($base_dir) : (),
      $subdirs_and_filename);

  return dir($bin_dir->volume,
    $bin_dir->as_foreign('Unix')->file(@subdirs_and_filename)->as_native
  )->stringify;
}


=head2 try_to_make_symlink($old_path, $new_path)

Creates a symlink if symlinks are supported on the platform.

Returns true iff symbolic links are supported on the platform.

Throws an exception if L<perlfunc/symlink> fails.

Example:

  my $symlinks_supported = try_to_make_symlink($old_path, $new_path);

=cut

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


=head2 try_to_make_fifo($path)

Creates a named pipe (FIFO) if named pipes are supported on the platform.

Returns true iff named pipes are supported on the platform.

Throws an exception if L<POSIX/mkfifo> fails.

Example:

  my $fifos_supported = try_to_make_fifo($path);

=cut

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

=head1 COPYRIGHT & LICENSE

Copyright 2009 Norbert Buchmüller, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
