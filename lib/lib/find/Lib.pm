package lib::find::Lib;

use warnings;
use strict;

use Tie::Scalar;
use base qw(Tie::StdScalar);

=head1 NAME

lib::find::Lib - lib::find internals - implement $lib::find::Lib tied scalar

=cut

sub FETCH
{
  my ($self) = (shift, @_);

  return $lib::find::Lib{caller()};
}

sub STORE
{
  my ($self, $value) = (shift, @_);

  return $lib::find::Lib{caller()} = $value;
}

1; # End of lib::find::Lib
