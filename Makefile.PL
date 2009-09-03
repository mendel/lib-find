use inc::Module::Install 0.91;

name     'FindLib';
all_from 'lib/FindLib.pm';

requires 'FindBin' => '1.49';
requires 'File::Spec' => '3.3';
requires 'Cwd' => '3.3';
requires 'Carp' => '1.08';

test_requires 'Test::Most' => '0.21';
if ($Module::Install::AUTHOR) {
  test_requires 'Test::Pod' => '1.22';
  test_requires 'Test::Pod::Coverage' => '1.08';
  test_requires 'Pod::Coverage' => '0.18';
}

configure_requires 'Module::Install::ExtraTests' => 0.006;

extra_tests;

auto_install;

WriteAll;
