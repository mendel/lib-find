package Module::To::Find;

our $magic = "lib::find";

@INC = ("lib::find-pre", @INC, "lib::find-post");

1;
