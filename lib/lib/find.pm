package lib::find;

#TODO tests for symlinked bin dirs
#TODO use $FindBin::Bin instead of ::RealBin (see FindBin::libs code (ie. it calls realpath() on the result of the concatenation of the dir parts and use that))
#TODO a nice goodie: consider all paths in $lib::find::libdir_names as UNIX paths (ie. do foreign_dir('Unix', $libdir_name)->as_native on them before using them)
#TODO in doc compare to Find::Lib and FindBin::libs, add them to SEE ALSO
#TODO create TODO tests (and add TODO doc) for inlined module case (ie. when in one file there are some auxiliary modules and the user asks for any of them)
#TODO rewrite SYNOPSIS and DESCRIPTION a bit: the module has two separate uses: 1. find the libdir of any or the current module, 2. scan dirs upwards to find a module and unshift its libdir to @INC

use warnings;
use strict;

use 5.005;

use FindBin;
use Cwd;
use Path::Class;
use Carp;

use lib::find::dir::Hash;
use lib::find::dir::Scalar;

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
    use lib $lib::find::dir->parent->subdir('stuff', 'lib');

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
wrong; not to speak about portability of your relative dir specifications).

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
resides. And will work on any platform that L<Path::Class> and L<Cwd> supports.

=head1 EXPORT

No exports.

C<< use lib::find 'MyApp::Common' >> is equivalent to C<< BEGIN {
lib::find::find_lib('MyApp::Common') } >> and C<< use lib::find; >> does not
call L</find_lib>.

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

A tied hash variable that returns the value of L</libdir_path> for the module
name used as the key:

    use lib::find 'MyApp::Common';

    # set $app_root to the absolute path of the 'myapp' dir (see the example in
    # the L</SYNOPSIS>)
    my $app_root = $lib::find::dir{'MyApp::Common'}->parent;

Since L<perlvar/%INC> is already set when the module searched for is being
compiled, you can use C<< $lib::find::dir{+__PACKAGE__} >> there. So you can
use libdirs relative to the libdir of any module:

    use lib::find;

    use lib $lib::find::dir{+__PACKAGE__}->parent->subdir('stuff', 'lib')->stringify;

See L</libdir_path> for description of the return value.

See also L</$lib::find::dir> for a more compact syntax.

=cut

tie our %dir, 'lib::find::dir::Hash', '%' . __PACKAGE__ . '::dir';

=head2 $lib::find::dir

A tied scalar variable that returns the value of the L</%lib::find::dir> hash
slot that corresponds to the current module (ie. where this variable evaluated
from); practically the same as C<< $lib::find::dir{+__PACKAGE__} >>.

Everything described at L</%lib::find::dir> applies to this variable, too.

This variable is especially convenient when you want to use libdirs relative to
the libdir of the current module:

    use lib::find;

    use lib $lib::find::dir->parent->subdir('stuff', 'lib')->stringify;

=cut

tie our $dir, 'lib::find::dir::Scalar', '$' . __PACKAGE__ . '::dir';

=head1 FUNCTIONS

=cut

sub import
{
  my ($caller, $module_name) = (shift, @_);

  return unless @_;

  goto \&find_lib;
}

=head2 module_inc_key($module_name)

Returns the key for the L<perlvar/%INC> hash that corresponds to
C<$module_name>. Returns C<undef> if C<$module_name> is not defined.

=cut

sub module_inc_key($)
{
  my ($module_name) = @_;

  return undef unless defined $module_name;

  (my $module_inc_key = "$module_name.pm") =~ s{::}{/}g;

  return $module_inc_key;
}


=head2 libdir_path($module_name)

Returns the libdir value for the given module name (if it's already loaded - it
uses L<perlvar/%INC>). The value returned is always an absolute path and is a
L<Path::Class::Dir> instance (using the local path conventions).

Strips off the module name parts from the the module file of C<$module_name>
found in L<perlvar/%INC> and returns the path of the libdir. Returns C<undef>
if C<$module_name> is not defined or if that module is not loaded.

Note: you should not store L<Path::Class::Dir> instances into C<@INC>, see
L<perlvar/@INC>. Stringify them before:

    use lib libdir_path('Some::Module')->parent->stringify;

=cut

sub libdir_path($)
{
  my ($module_name) = @_;

  return undef unless defined $module_name;

  my $module_filename = $INC{module_inc_key($module_name)};

  return undef unless defined $module_filename;

  my $module_file = file($module_filename)->as_foreign('Unix');

  (my $relative_module_file = "$module_name.pm") =~ s{::}{/}g;

  my $libdir = substr $module_file, 0, -(length($relative_module_file) + 1);
  my $actual_relative_module_file =
    substr $module_file, -length($relative_module_file);

  croak "Inconsistent \%INC: '$module_name' => '$module_filename'"
    if $actual_relative_module_file ne $relative_module_file;

  return dir(Cwd::realpath($libdir));
}

=head2 find_lib($module_name)

Performs the scanning of parent dirs and prepending the libdir to C<@INC> on
success.

No-op if C<$module_name> is not defined.

If the C<< $ENV{LIB_FIND_TRACE} >> environment variable is set to 1, logs
(using L<perldoc/warn>) the module names and libdirs found. If it is set to 2,
also logs the libdir candidates found.

=cut

sub find_lib
{
  my ($module_name) = @_;

  return unless defined $module_name;

  my $module_inc_key = module_inc_key($module_name);

  # try if it's already in @INC
  eval "require $module_name";

  if (!exists $INC{$module_inc_key}) {
    my @libdirs;

    my $root_dir = dir('');
    my $dir = dir($FindBin::RealBin);

    my $scan_iterations = 0;
    do {
      push @libdirs, grep { -d || (-l && -d readlink) }
        map { $dir->subdir($_)->stringify } @libdir_names;
      $dir = dir(Cwd::realpath($dir->parent));
    } while ($dir ne $root_dir &&
             $scan_iterations++ < $max_scan_iterations);

    if (!@libdirs) {
      croak "No libdir candidates (" .
            join(", ", map { "'$_'" } @libdir_names) .
            ") found when scanning upwards from '$FindBin::RealBin'";
    }
    warn __PACKAGE__ . ": libdir candidates for '$module_name': " .
      join(", ", map { "'$_'" } @libdirs) . "\n"
        if ($ENV{LIB_FIND_TRACE} || 0) >= 2;

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

  warn __PACKAGE__ . ": found '$module_name' at '$INC{$module_inc_key}' " .
    "(prepended to \@INC)\n"
      if ($ENV{LIB_FIND_TRACE} || 0) >= 1;
}

=head1 TODO

=over

=item *

option to specify alternatives to ['blib', 'lib'] (besides setting
C<$lib::find::libdir_names>)

=item *

how does it work when there are subrefs in @INC? (eg. scripts running from PAR
archives)

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
