use inc::Module::Install;

name     'FindLib';
all_from 'lib/FindLib.pm';
author   'Norbert Buchmüller <norbi@nix.hu>';
license  'perl';

build_requires 'Test::More';

auto_install;

WriteAll;

