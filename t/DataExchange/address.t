use 5.010;
use strict;
use warnings;

use Test::Most;
use Encode;
use Path::Class;
use FindBin '$Bin';
use DateTime;
use utf8;

use_ok('Business::DPD::Address');
use_ok('Business::DPD');

my $dpd = Business::DPD->new;
$dpd->connect_schema;

my $address = Business::DPD::Address->new($dpd, {
    name1 => 'DELICom DPD GmbH',
    street => 'Wailandtstrasse 1',
    houseno => '',
    country => 'DE',
    state => 'state',
    postal => '63741',
    city => 'Aschaffenburg',
    contact => '',
    phone => '06021/ 0815',
    fax => '06021/ 0816',
    email => 'test.dpd@dpd.com',
    comment => '',
});
is(
    $address->as_mpsexpdata,
    'DELICom DPD GmbH;;Wailandtstrasse 1;;276;63741;Aschaffenburg;;06021/ 0815;06021/ 0816;test.dpd@dpd.com;;',
    'as_mpsexpdata()'
);
is(
    $address->as_mpsexpdata(state => 1),
    'DELICom DPD GmbH;;Wailandtstrasse 1;;276;state;63741;Aschaffenburg;;06021/ 0815;06021/ 0816;test.dpd@dpd.com;;',
    'as_mpsexpdata(state => 1)'
);

done_testing;
