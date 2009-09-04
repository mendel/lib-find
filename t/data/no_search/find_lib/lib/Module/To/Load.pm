package Module::To::Load;

use FindLib ();

FindLib::find_lib();

our $lib_dir = $FindLib::Lib{+__PACKAGE__};

1;
