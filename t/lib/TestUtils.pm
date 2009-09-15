package TestUtils;

use strict;
use warnings;

use FindBin;
use Path::Class;

use base qw(Exporter);

our @EXPORT = qw(
  &data_dir
  &data_file
);

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
  my ($test_name) = ($FindBin::Script =~ /^\d+[_-](.*)\.t$/);

  return $test_name;
}

sub data_dir
{
  my ($subdir) = @_;

  $subdir = "" if !defined $subdir;

  my $test_name = _test_name();

  my $bin_dir = dir($FindBin::Bin);

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

  my $bin_dir = dir($FindBin::Bin);

  return dir($bin_dir->volume,
    $bin_dir->as_foreign('Unix')
      ->file("data/$test_name/$subdirs_and_filename")->as_native
  )->stringify;
}

1;
