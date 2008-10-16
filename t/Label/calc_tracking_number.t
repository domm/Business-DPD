use 5.010;
use strict;
use warnings;

use Test::More tests => 2;
use Test::NoWarnings;

use Business::DPD;
use Business::DPD::Label;
my $dpd = Business::DPD->new;

my $label = Business::DPD::Label->new($dpd,{
    zip             => '12555',
    country         => 'DE',
    depot           => '0190',
    serial          => '5002345615',
    service_code    => '101',
});

$label->calc_tracking_number;

is($label->tracking_number,'01905002345615Y','tracking number');

