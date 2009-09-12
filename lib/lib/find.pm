package lib::find;

#TODO convert %lib::find::dir into a tied hash (so the libdir of any module can be queried, not only those that are found by lib::find) ?
#TODO rewrite SYNOPSIS and DESCRIPTION a bit: the module has two separate uses: 1. find the libdir of any or the current module, 2. scan dirs upwards to find a module and unshift its libdir to @INC

use warnings;
use strict;

use 5.005;

use FindBin;
use File::Spec;
use Cwd;
use Carp;
use Data::Thunk;

use lib::find::dir;

=head1 NAME

lib::find - Finds a module scanning upwards from $FindBin::RealBin, adds its dir to @INC

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

This module starts scanning for directories named C<blib> or C<lib> in the
parent directories of C<$FindBin::RealBin>, starting with C<$FindBin::RealBin>
and going upwards. For each such libdir candidate it tries to C<require> the
named module from it. Stops on the first module found and unshifts its libdir
into C<@INC>.

    # assume this directory layout:
    #
    # myapp
    # |-- bin
    # |   `-- cron
    # |       `-- foo.pl
    # |-- script
    # |   `-- myapp_server.pl
    # `-- lib
    #     |-- MyApp.pm
    #     |   |-- Common.pm
    #     |   `-- Schema.pm
    #     `-- MySchema.pm
    #

    # in bin/cron/foo.pl
    use lib::find 'MyApp::Common'; # finds the dir upwards that contains
                                 # MyApp/Common.pm and prepends it to @INC
    use MySchema;                # now found

    # in script/myapp_server.pl
    use lib::find 'MyApp::Common'; # finds the dir upwards that contains
                                 # MyApp/Common.pm and prepends it to @INC
    use MyApp;                   # now found

But there's more, you can tweak C<@INC> from the module being searched for:

    # assume this directory layout:
    #
    # myapp
    # |-- bin
    # |   `-- cron
    # |       `-- foo.pl
    # |-- script
    # |   `-- myapp_server.pl
    # |-- lib
    # |   |-- MyApp.pm
    # |   |   |-- Common.pm
    # |   |   `-- Schema.pm
    # |   `-- MySchema.pm
    # `-- stuff
    #     `-- lib
    #         `-- Thingy.pm
    #

    # in MyApp/Common.pm
    use lib::find;
    use lib "$lib::find::dir/../stuff/lib";

    # in bin/cron/foo.pl
    use lib::find 'MyApp::Common'; # finds the dir upwards that contains
                                 # My/App.pm and prepends it to @INC
    use MyApp::Schema;           # now found
    use Thingy;                  # also found b/c we added stuff/lib
                                 # to @INC

=head1 DISCLAIMER

This is ALPHA SOFTWARE. Use at your own risk. Features may change.

=head1 DESCRIPTION

Probably you have many different checkouts of the same application or many
similar applications (eg. L<Catalyst> based webapps) in different places
throughout your development machine. Probably you have dozens of utility
scripts for each of them. Probably you don't want to set an environment
variable to a different value every time you start working in a different
checkout tree (just to make sure those scripts will find the correct libdir
whichever dir you are in when you start them). So you decide to use L<FindBin>.
Fine so far (though not too elegant and introduces a 'moving part' that can go
wrong).

From time to time you probably want to freely rearrange those utility scripts
into a continuously morphing directory hierarchy under your C<bin> or C<script>
directory - to put in some 'order and method'. And on such occasions probably
you don't want to edit them one by one to match their hard-wired relative paths
to C<$FindBin::Bin>...

This is where this module helps you.

Previously you used to hard-wire paths relative to C<$FindBin::Bin> into the
scripts like that:

    use FindBin;
    use lib "$FindBin::Bin/../..";

    use MyApp::Common;
    use MyApp::Schema;

Now you can write this instead:

    use lib::find 'MyApp::Common';

    use MyApp::Common;
    use MyApp::Schema;

And your script will automagically find the dir where the MyApp::Common module
resides.

=head1 EXPORT

No exports.

=head1 VARIABLES

=cut

=head2 $lib::find::max_scan_iterations

The scanning of parent directories stops after going this many levels upwards
(to avoid infinite loops).

The default value is 100.

=cut

our $max_scan_iterations = 100;

=head2 @lib::find::libdir_names

The relative directory names to look for as libdirs.

The default is ('blib', 'lib').

=cut

our @libdir_names = qw(blib lib);

=head2 %lib::find::dir

Contains the module name - libdir pairs for all the modules that L<lib::find> was
used to find.

    use lib::find 'MyApp::Common';

    # set $app_root to the absolute path of the 'myapp' dir (see the example in
    # the L</SYNOPSIS>)
    my $app_root = "$lib::find::dir{'MyApp::Common'}/..";

It is already set when the module searched for is being compiled (ie. you can
use C<< $lib::find::dir{+__PACKAGE__} >> there). (To be perfectly honest, it is
set to a thunk (lazily evaluated value) provided by L<Data::Thunk>, but most of
the time it does not matter for you.)

So you can use libdirs relative to the libdir of the current module:

    use lib::find;

    use lib "$lib::find::dir{+__PACKAGE__}/../stuff/lib";

See also L<$lib::find::dir>.

=cut

our %dir;

=head2 $lib::find::dir

A tied scalar variable that returns the value of L<%lib::find::dir> hash slot that
corresponds to the current module (ie. where this variable evaluated from).

Everything described at L<%lib::find::dir> applies to this variable, too.

This variable is especially convenient when you want to use libdirs relative to
the libdir of the current module:

    use lib::find;

    use lib "$lib::find::dir/../stuff/lib";

=cut

tie our $dir, 'lib::find::dir';

=head1 FUNCTIONS

=cut

sub import
{
  my ($caller, $module_name) = (shift, @_);

  goto \&find_lib;
}

#
# my $path = _append_dir_to_path($path, $dir);
#
# Appends C<$dir> to C<$path> (using L<File::Spec>).
#
sub _append_dir_to_path($$)
{
  my ($path, $dir) = @_;

  my ($volume, $dirs) = File::Spec->splitpath($path, 1);
  my @dirs = File::Spec->splitdir($dirs);

  return File::Spec->catpath(
    $volume,
    File::Spec->catdir(@dirs, $dir),
    ''
  );
}

#
# my $libdir_path = _libdir_path($module_file, $module_name);
#
# Strips off the module name parts of C<$module_name> from the C<$module_file>
# and returns the path of the libdir.
#
sub _libdir_path($$)
{
  my ($module_file, $module_name) = @_;

  return undef unless defined $module_file;

  my @module_name_elems = split /::/, $module_name;
  $module_name_elems[-1] .= ".pm";

  my ($volume, $dir, $filename) = File::Spec->splitpath($module_file);
  my @dirs = File::Spec->splitdir($dir);
  pop @dirs if (@dirs > 1) && $dirs[-1] eq '';
  my @module_path_elems = (@dirs, $filename);

  my @module_path_elems_to_remove =
    splice @module_path_elems, -@module_name_elems;

  foreach my $i (1..@module_name_elems) {
    croak "Inconsistent \%INC: '$module_name' => '$module_file'" if
      $module_name_elems[-$i] ne $module_path_elems_to_remove[-$i];
  }

  return File::Spec->catpath(
    $volume,
    File::Spec->catdir(@module_path_elems),
    ''
  );
}

=head2 find_lib([$module_name])

Performs the scanning of parent dirs and prepending the libdir to C<@INC> on
success.

If C<$module_name> is omitted, it defaults to the current package
(C<__PACKAGE__>). This does not make much sense when considered as searching
for the libdir of the module (it's already known), but as a side-effect it sets
C<< $lib::find::dir{+__PACKAGE__} >> (also available as C<$lib::find::dir>).

C<< use lib::find 'MyApp::Common' >> is equivalent to C<<
lib::find::find_lib('MyApp::Common') >> (and C<< use lib::find; >> is equivalent to
C<< lib::find::find_lib() >>).

=cut

sub find_lib
{
  my ($module_name) = @_;

  $module_name = caller unless defined $module_name;

  (my $module_inc_key = "$module_name.pm") =~ s{::}{/}g;

  $dir{$module_name} = lazy {
    _libdir_path($INC{$module_inc_key}, $module_name)
  };

  # try if it's already in @INC
  eval "require $module_name";

  if (!exists $INC{$module_inc_key}) {
    my @libdirs;

    my $dir = $FindBin::RealBin;

    my $scan_iterations = 0;
    do {
      push @libdirs, grep { -e $_ }
        map { _append_dir_to_path($dir, $_) } @libdir_names;
      $dir = Cwd::realpath(_append_dir_to_path($dir, File::Spec->updir));
    } while ($dir ne File::Spec->rootdir &&
             $scan_iterations++ < $max_scan_iterations);

    if (!@libdirs) {
      croak "No libdir candidates (" .
            join(", ", map { "'$_'" } @libdir_names) .
            ") found when scanning upwards from '$FindBin::RealBin'";
    }

    foreach my $libdir (@libdirs) {
      unshift @INC, $libdir;
      eval "require $module_name";
      last if exists $INC{$module_inc_key};
      shift @INC;
    }
  }

  if (!defined $INC{$module_inc_key}) {
    croak "Module '$module_name' not found when scanning upwards from " .
          "'$FindBin::RealBin'";
  }
}

=head1 TODO

=over

=item *

option to specify alternatives to ['blib', 'lib'] (besides setting
C<$lib::find::libdir_names>)

=item *

how does it work when there are subrefs in @INC? (eg. scripts running from PAR
archives)

=item *

switch to L<Variable::Lazy> instead of L<Data::Thunk> once L<Variable::Lazy>
handles putting thunks into hash slots

=back

=head1 CAVEATS

=over

=item *

It uses C<$FindBin::RealBin> instead of C<$FindBin::Bin> (see
L<FindBin/"EXPORTABLE VARIABLES">). It's hard to fix, as the implementation
depends on L<Cwd/realpath> (and that converts C<$FindBin::Bin> into
C<$FindBin::RealBin> anyways).

=item *

It does not C<use> the module for you, just C<require> it - you have to C<use>
it yourself. And that's fine.

=item *

If the module searched for can be found using your original C<@INC>, then no
parent directory scanning is performed (and consequently nothing is prepended
to C<@INC>). (It's near to impossible to implement shadowing other modules on
C<@INC> while using Perl's internal module search implementation to find the
module.)

=back

=head1 SEE ALSO

L<FindBin>, L<Cwd>

=head1 AUTHOR

Norbert Buchmüller, C<< <norbi at nix.hu> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-lib-find at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=lib-find>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc lib::find

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=lib-find>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/lib-find>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/lib-find>

=item * Search CPAN

L<http://search.cpan.org/dist/lib-find/>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2009 Norbert Buchmüller, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of lib::find
