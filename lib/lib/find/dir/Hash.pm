package lib::find::dir::Hash;

use warnings;
use strict;

use Carp;

=head1 NAME

lib::find::dir::Hash - lib::find internals - implement %lib::find::dir tied hash

=cut

=head2 FUNCTIONS

=cut

sub _modify_hash
{
  my ($self) = (shift, @_);

  croak "You cannot modify the $self->{var_name} variable";
}

=head2 TIEHASH

See L<perltie/"Tying Hashes">.

=cut

sub TIEHASH
{
  my ($class, $var_name) = (shift, @_);

  my $self = bless {}, $class;

  $self->{var_name} = $var_name;

  return $self;
}

=head2 FETCH

See L<perltie/"Tying Hashes">.

=cut

sub FETCH
{
  my ($self, $module_name) = (shift, @_);

  return lib::find::_libdir_path($module_name);
}

=head2 EXISTS

See L<perltie/"Tying Hashes">.

=cut

sub EXISTS
{
  my ($self, $module_name) = (shift, @_);

  my $module_inc_key = lib::find::_module_inc_key($module_name);

  return
    defined $module_inc_key
      ? exists $INC{$module_inc_key}
      : undef;
}

=head2 FIRSTKEY

See L<perltie/"Tying Hashes">.

=cut

sub FIRSTKEY
{
  my ($self) = (shift, @_);

  $self->{inc_keys_snapshot} = [ keys %INC ];

  return $self->NEXTKEY();
}

=head2 NEXTKEY

See L<perltie/"Tying Hashes">.

=cut

sub NEXTKEY
{
  my ($self) = (shift, @_);

  my $module_inc_key = shift @{$self->{inc_keys_snapshot}};

  return undef unless defined $module_inc_key;

  my $module_name = $module_inc_key;
  $module_name =~ s/\.pm$//;
  $module_name =~ s{/}{::}g;

  return $module_name;
}

=head2 SCALAR

See L<perltie/"Tying Hashes">.

=cut

sub SCALAR
{
  my ($self) = (shift, @_);

  return scalar %INC;
}

*STORE = \&_modify_hash;
*DELETE = \&_modify_hash;
*CLEAR = \&_modify_hash;
*UNTIE = \&_modify_hash;

1; # End of lib::find::dir::Hash
