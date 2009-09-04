package Module::To::Load;

use FindLib ();

FindLib::findlib();

our $lib_dir = $FindLib::lib{+__PACKAGE__};

1;
