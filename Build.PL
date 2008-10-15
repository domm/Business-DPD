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
    #add_to_cleanup     => ['DBIx-SchemaChecksum-*'],
    create_makefile_pl => 'passthrough',
);

$builder->create_build_script();
