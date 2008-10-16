use 5.010;
use strict;
use warnings;

use Test::More tests => 4;
use Test::NoWarnings;

use Business::DPD;
use Business::DPD::Label;
my $dpd = Business::DPD->new;
$dpd->connect_schema;
my $label = Business::DPD::Label->new($dpd,{
    zip             => '12555',
    country         => 'DE',
    depot           => '0190',
    serial          => '5002345615',
    service_code    => '101',
});

$label->calc_routing;

is($label->o_sort,'2L18','o_sort');
is($label->d_sort,'D030','d_sort');
is($label->d_depot,'0112','d_depot');

