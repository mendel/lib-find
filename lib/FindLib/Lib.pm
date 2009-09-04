package FindLib::Lib;

use warnings;
use strict;

use Tie::Scalar;
use base qw(Tie::StdScalar);

=head1 NAME

FindLib::Lib - FindLib internals - implement $FindBin::Lib tied scalar

=cut

sub FETCH
{
  my ($self) = (shift, @_);

  return $FindLib::Lib{caller()};
}

sub STORE
{
  my ($self, $value) = (shift, @_);

  return $FindLib::Lib{caller()} = $value;
}

1; # End of FindLib::Lib
