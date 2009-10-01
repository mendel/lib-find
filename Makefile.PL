#!/usr/bin/env perl

use strict;
use warnings;

use inc::Module::Install 0.91;

name 'lib-find';
all_from 'lib/lib/find.pm';
readme_from 'lib/lib/find.pm' => 'clean';
auto_set_repository;

requires 'FindBin' => '1.49';
requires 'Path::Class' => '0.16';
requires 'Cwd' => '3.3';
requires 'Carp' => '1.08';
requires 'List::MoreUtils' => '0.22';

test_requires 'Test::Most' => '0.21';
test_requires 'Test::More' => '0.92';
test_requires 'Test::Differences' => '0.4801';
test_requires 'Test::Deep' => '0.103';
test_requires 'Test::Warn' => '0.21';
test_requires 'Test::Exception' => '0.27';

author_requires 'Test::Pod' => '1.22';
author_requires 'Test::Pod::Coverage' => '1.08';
author_requires 'Pod::Coverage' => '0.18';

configure_requires 'Module::Install::ExtraTests' => '0.006';
configure_requires 'Module::Install::ReadmeFromPod' => '0.06';
configure_requires 'Module::Install::AuthorRequires' => '0.02';
configure_requires 'Module::Install::Repository' => '0.06';

extra_tests;

auto_install;

WriteAll;
