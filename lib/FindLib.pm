package FindLib;

#TODO tests for modules with file permisson problems, syntax errors, missing 1; at the end
#TODO some way to find the app root: either a separate module (use FindApp 'My::App'; say $FindApp::Root;) or dynamically create variables in this package (use FindLib 'My::App'; say $FindLib::My::App::lib;)
#TODO describe how it works (ie. require()s the module - but does not use() it, you have to do it yourself)
#TODO document what happens if the dir of the module is already in @INC (ie. tries to find the module using the original @INC first, no shadowing - impossible to implement properly)
#TODO option to specify alternatives to ['blib', 'lib']
#TODO what about subrefs in @INC? (eg. scripts running from PAR archives)

use warnings;
use strict;

use 5.005;

use FindBin;
use File::Spec;
use Cwd;
use Carp;

=head1 NAME

FindLib - Finds a libdir containing a module scanning upwards from $FindBin::RealBin

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use FindLib qw(My::App);  # finds the dir upwards that contains My/App.pm
                              # then adds the libdir of My::App to @INC
    use My::Other::Module;    # now found

=head1 EXPORT

No exports.

=head1 VARIABLES

=cut

=head2 $FindLib::max_scan_iterations

The scanning of parent directories stops after going this many levels upwards
(to avoid infinite loops).

The default value is 100.

=cut

our $max_scan_iterations = 100;

=head2 @FindLib::libdir_names

The relative directory names to look for as libdirs.

The default is ('blib', 'lib').

=cut

our @libdir_names = qw(blib lib);

=head1 FUNCTIONS

=cut

sub import
{
  my ($caller, $module_name) = (shift, @_);

  findlib($module_name);
}

=head2 findlib($module_name)

FIXME

=cut

sub findlib
{
  my ($module_name) = @_;

  (my $module_inc_key = "$module_name.pm") =~ s{::}{/}g;

  # try if it's already in @INC
  eval "require $module_name";

  if (!exists $INC{$module_inc_key}) {
    my @libdirs;

    my $dir = $FindBin::RealBin;

    my $scan_iterations = 0;
    do {
      push @libdirs, grep { -e $_ }
        map { File::Spec->catfile($dir, $_) } @libdir_names;
      $dir = Cwd::realpath(File::Spec->catfile($dir, File::Spec->updir));
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
      last if $@ eq "";
      shift @INC;
    }
  }

  if (!exists $INC{$module_inc_key}) {
    croak "Module '$module_name' not found when scanning upwards from '$FindBin::RealBin'";
  }
}

=head1 SEE ALSO

L<FindBin>

=head1 AUTHOR

Norbert Buchmüller, C<< <norbi at nix.hu> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-findlib at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=FindLib>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc FindLib


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=FindLib>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/FindLib>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/FindLib>

=item * Search CPAN

L<http://search.cpan.org/dist/FindLib/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Norbert Buchmüller, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of FindLib
