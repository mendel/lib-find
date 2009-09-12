package Module::To::Load;

use lib::find ();

lib::find::find_lib(undef);

our $lib_dir = $lib::find::dir{+__PACKAGE__};

1;
