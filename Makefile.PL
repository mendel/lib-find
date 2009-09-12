use inc::Module::Install 0.91;

name     'lib-find';
all_from 'lib/lib/find.pm';
readme_from 'lib/lib/find.pm' => 'clean';
resources 'repository'  => 'http://github.com/mendel/lib-find/tree';

requires 'FindBin' => '1.49';
requires 'File::Spec' => '3.3';
requires 'Cwd' => '3.3';
requires 'Carp' => '1.08';
requires 'Tie::Scalar' => '1.00';

test_requires 'Test::Most' => '0.21';
if ($Module::Install::AUTHOR) {
  test_requires 'Test::Pod' => '1.22';
  test_requires 'Test::Pod::Coverage' => '1.08';
  test_requires 'Pod::Coverage' => '0.18';
}

configure_requires 'Module::Install::ExtraTests' => 0.006;
configure_requires 'Module::Install::ReadmeFromPod' => 0.06;

extra_tests;

auto_install;

WriteAll;
