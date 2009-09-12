package lib::find::dir::Scalar;

use warnings;
use strict;

use Tie::Scalar;
use base qw(Tie::StdScalar);

=head1 NAME

lib::find::dir::Scalar - lib::find internals - implement $lib::find::dir tied scalar

=cut

sub FETCH
{
  my ($self) = (shift, @_);

  return $lib::find::dir{caller()};
}

sub STORE
{
  my ($self, $value) = (shift, @_);

  return $lib::find::dir{caller()} = $value;
}

1; # End of lib::find::dir
