use inc::Module::Install 0.91;

name     'lib-find';
all_from 'lib/lib/find.pm';
readme_from 'lib/lib/find.pm' => 'clean';
resources 'repository'  => 'http://github.com/mendel/lib-find/tree';

requires 'FindBin' => '1.49';
requires 'File::Spec' => '3.3';
requires 'Cwd' => '3.3';
requires 'Carp' => '1.08';

test_requires 'Test::Most' => '0.21';
test_requires 'List::MoreUtils' => '0.22';
test_requires 'Path::Class' => '0.16';

author_requires 'Test::Pod' => '1.22';
author_requires 'Test::Pod::Coverage' => '1.08';
author_requires 'Pod::Coverage' => '0.18';

configure_requires 'Module::Install::ExtraTests' => '0.006';
configure_requires 'Module::Install::ReadmeFromPod' => '0.06';
configure_requires 'Module::Install::AuthorRequires' => '0.02';

extra_tests;

auto_install;

WriteAll;
