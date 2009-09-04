#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;

use Test::Most;

use FindLib ();

{
  my $base_dir = "$FindBin::Bin/data/failing_require/a";

  local $FindLib::max_scan_iterations = 1;

  my @newINC;
  my %newINC;

  {
    local @INC = @INC;
    local %INC = %INC;
    local $FindBin::RealBin = "$base_dir/bin";

    lives_ok {
      FindLib::findlib('Module::With::No::Content');
    } "findlib() does not die even if the module does not declare the package";

    @newINC = @INC;
    %newINC = %INC;
  }

  cmp_deeply(
    \@newINC,
    ["$base_dir/lib", @INC],
    "findlib() prepends the right libdir to \@INC even when the module does not " .
    "declare the package"
  );

  is(
    $newINC{'Module/With/No/Content.pm'},
    "$base_dir/lib/Module/With/No/Content.pm",
    "findlib() sets the \%INC slot to the right path even when the module does " .
    "not declare the package"
  );
}

{
  my $base_dir = "$FindBin::Bin/data/failing_require/a";

  local $FindLib::max_scan_iterations = 1;

  my @newINC;
  my %newINC;

  {
    local @INC = @INC;
    local %INC = %INC;
    local $FindBin::RealBin = "$base_dir/bin";

    throws_ok {
      local $SIG{__WARN__} = sub { };
      FindLib::findlib('Module::With::Syntax::Error');
    } qr/^Module 'Module::With::Syntax::Error' not found when scanning upwards from '\Q$FindBin::RealBin\E'/,
      "findlib() dies with the proper error message if the module cannot be " .
      "required b/c of a syntax error";

    @newINC = @INC;
    %newINC = %INC;
  }

  cmp_deeply(
    \@newINC,
    ["$base_dir/lib", @INC],
    "findlib() prepends the right libdir to \@INC even when the module cannot " .
    "be required b/c of a syntax error"
  );

  ok(
    exists $newINC{'Module/With/Syntax/Error.pm'},
    "findlib() populates the \%INC slot when the module cannot be required b/c " .
    "of a syntax error"
  );

  is(
    $newINC{'Module/With/Syntax/Error.pm'},
    undef,
    "findlib() sets the \%INC slot to undef when the module cannot be required " .
    "b/c of a syntax error"
  );
}

{
  my $base_dir = "$FindBin::Bin/data/failing_require/a";

  local $FindLib::max_scan_iterations = 1;

  my @newINC;
  my %newINC;

  {
    local @INC = @INC;
    local %INC = %INC;
    local $FindBin::RealBin = "$base_dir/bin";

    throws_ok {
      FindLib::findlib('Module::That::Returns::False');
    } qr/^Module 'Module::That::Returns::False' not found when scanning upwards from '\Q$FindBin::RealBin\E'/,
      "findlib() dies with the proper error message if the module cannot be " .
      "required b/c it returns false";

    @newINC = @INC;
    %newINC = %INC;
  }

  cmp_deeply(
    \@newINC,
    ["$base_dir/lib", @INC],
    "findlib() prepends the right libdir to \@INC even when the module cannot " .
    "be required b/c it returns false"
  );

  ok(
    exists $newINC{'Module/That/Returns/False.pm'},
    "findlib() populates the \%INC slot when the module cannot be required b/c " .
    "it returns false"
  );

  is(
    $newINC{'Module/That/Returns/False.pm'},
    undef,
    "findlib() sets the \%INC slot to undef when the module cannot be required " .
    "b/c it returns false"
  );
}


{
  my $base_dir = "$FindBin::Bin/data/failing_require";

  local @INC = ("$base_dir/a/lib", @INC);
  local $FindLib::max_scan_iterations = 1;

  my @newINC;
  my %newINC;

  {
    local @INC = @INC;
    local %INC = %INC;
    local $FindBin::RealBin = "$base_dir/b/bin";

    lives_ok {
      FindLib::findlib('Module::With::No::Content');
    } "findlib() does not die even if the module does not declare the package " .
      "(libdir already in \@INC)";

    @newINC = @INC;
    %newINC = %INC;
  }

  cmp_deeply(
    \@newINC,
    \@INC,
    "\@INC is not changed if the module can be found using the original \@INC " .
    "even when the module does not declare the package (libdir already in \@INC)"
  );

  is(
    $newINC{'Module/With/No/Content.pm'},
    "$base_dir/a/lib/Module/With/No/Content.pm",
    "findlib() sets the \%INC slot to the right path even when the module does " .
    "not declare the package (libdir already in \@INC)"
  );
}

{
  my $base_dir = "$FindBin::Bin/data/failing_require";

  local @INC = ("$base_dir/a/lib", @INC);
  local $FindLib::max_scan_iterations = 1;

  my @newINC;
  my %newINC;

  {
    local @INC = @INC;
    local %INC = %INC;
    local $FindBin::RealBin = "$base_dir/b/bin";

    throws_ok {
      local $SIG{__WARN__} = sub { };
      FindLib::findlib('Module::With::Syntax::Error');
    } qr/^Module 'Module::With::Syntax::Error' not found when scanning upwards from '\Q$FindBin::RealBin\E'/,
      "findlib() dies with the proper error message if the module cannot be " .
      "required b/c of a syntax error (libdir already in \@INC)";

    @newINC = @INC;
    %newINC = %INC;
  }

  cmp_deeply(
    \@newINC,
    \@INC,
    "\@INC is not changed if the module can be found using the original \@INC " .
    "even when the module cannot be required b/c of a syntax error (libdir " .
    "already in \@INC)"
  );

  ok(
    exists $newINC{'Module/With/Syntax/Error.pm'},
    "findlib() populates the \%INC slot when the module cannot be required b/c " .
    "of a syntax error (libdir already in \@INC)"
  );

  is(
    $newINC{'Module/With/Syntax/Error.pm'},
    undef,
    "findlib() sets the \%INC slot to undef when the module cannot be required " .
    "b/c of a syntax error (libdir already in \@INC)"
  );
}

{
  my $base_dir = "$FindBin::Bin/data/failing_require";

  local @INC = ("$base_dir/a/lib", @INC);
  local $FindLib::max_scan_iterations = 1;

  my @newINC;
  my %newINC;

  {
    local @INC = @INC;
    local %INC = %INC;
    local $FindBin::RealBin = "$base_dir/b/bin";

    throws_ok {
      FindLib::findlib('Module::That::Returns::False');
    } qr/^Module 'Module::That::Returns::False' not found when scanning upwards from '\Q$FindBin::RealBin\E'/,
      "findlib() dies with the proper error message if the module cannot be " .
      "required b/c it returns false (libdir already in \@INC)";

    @newINC = @INC;
    %newINC = %INC;
  }

  cmp_deeply(
    \@newINC,
    \@INC,
    "\@INC is not changed if the module can be found using the original \@INC " .
    "even when the module cannot be required b/c it returns false (libdir " .
    "already in \@INC)"
  );

  ok(
    exists $newINC{'Module/That/Returns/False.pm'},
    "findlib() populates the \%INC slot when the module cannot be required b/c " .
    "it returns false (libdir already in \@INC)"
  );

  is(
    $newINC{'Module/That/Returns/False.pm'},
    undef,
    "findlib() sets the \%INC slot to undef when the module cannot be required " .
    "b/c it returns false (libdir already in \@INC)"
  );
}

done_testing;
