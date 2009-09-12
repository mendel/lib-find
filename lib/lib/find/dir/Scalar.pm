package lib::find::dir::Scalar;

use warnings;
use strict;

use Carp;

=head1 NAME

lib::find::dir::Scalar - lib::find internals - implement $lib::find::dir tied scalar

=cut

=head1 FUNCTIONS

=cut

sub _modify_scalar
{
  my ($self) = (shift, @_);

  croak "You cannot modify the $self->{var_name} variable";
}

=head2 TIESCALAR

See L<perltie/"Tying Scalars">.

=cut

sub TIESCALAR
{
  my ($class, $var_name) = (shift, @_);

  my $self = bless {}, $class;

  $self->{var_name} = $var_name;

  return $self;
}

=head2 FETCH

See L<perltie/"Tying Scalars">.

=cut

sub FETCH
{
  my ($self) = (shift, @_);

  return $lib::find::dir{caller()};
}

*STORE = \&_modify_scalar;
*UNTIE = \&_modify_scalar;

1; # End of lib::find::dir::Scalar
