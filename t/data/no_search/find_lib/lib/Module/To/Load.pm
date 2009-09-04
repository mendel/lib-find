package Module::To::Load;

use FindLib ();

FindLib::find_lib();

our $lib_dir = $FindLib::lib{+__PACKAGE__};

1;
