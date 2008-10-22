use strict;
use warnings;
use Module::Build;
use 5.010;

my $builder = Module::Build->new(
    module_name       => 'Business::DPD',
    license           => 'perl',
    dist_author       => 'RevDev',
    dist_version_from => 'lib/Business/DPD.pm',
    build_requires    => {
        'Test::More'       => 0,
    },
    requires => {
        'perl'             => '5.010',
    },
    
    add_to_cleanup     => ['Business-DPD-*'],
    create_makefile_pl => 'passthrough',
    recursive_test_files => 1,
);
$builder->add_build_element('sqlite');
$builder->add_build_element('pdf');
$builder->add_build_element('TTF');
$builder->create_build_script();
