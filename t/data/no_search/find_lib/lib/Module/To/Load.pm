package Module::To::Load;

use lib::find ();

lib::find::find_lib();

our $lib_dir = $lib::find::Lib{+__PACKAGE__};

1;
