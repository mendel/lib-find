package Module::To::Find;

our $magic = "FindLib";

@INC = ("FindLibPre", @INC, "FindLibPost");

1;
