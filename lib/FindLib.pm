package FindLib;

#TODO describe how it works (ie. require()s the module - but does not use() it, you have to do it yourself)
#TODO tests: use()ing a module that itself modifies @INC (the modification must be permanent); testing that in the module that is to be found @INC only contains the original value of @INC plus the dir of the module (ie. no map { "$_/lib", "$_/blib" } @parent_dirs_of_FindBin_Bin is in @INC)
#TODO document that it prefers modules in the updir libdirs over the system @INC paths
#TODO option to specify alternatives to ['blib', 'lib']
#TODO what about subrefs in @INC? (eg. scripts running from PAR archives)

use warnings;
use strict;

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

  (my $module_filename = "$module_name.pm") =~ s{::}{/}g;

  if (!exists $INC{$module_filename}) {
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
      @INC = grep { $_ ne $libdir } @INC;
    }
  }

  if (!exists $INC{$module_filename}) {
    croak "Module '$module_name' not found when scanning upwards from '$FindBin::RealBin'";
  }

  push @INC, $INC{$module_filename};
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
