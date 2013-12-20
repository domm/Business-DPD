use 5.010;
use strict;
use warnings;
use utf8;

use Test::Most;

use Path::Class qw(file);
use FindBin '$Bin';

use Business::DPD::Parcel;

binmode(STDOUT,':encoding(UTF-8)');

if ($ENV{DO_LIVE_TEST}) {
    my $dpd_parcel = Business::DPD::Parcel->new(
        tracking_number => '06505010903049',
    );
    ok($dpd_parcel->dpd_extranet_page, 'fetch extranet page');
    #file($Bin, 'tracing01.html')->spew($dpd_parcel->dpd_extranet_page);
}

my $web_page = file($Bin, 'tracing01.html')->slurp;
my $dpd_parcel = Business::DPD::Parcel->new(
    tracking_number => '06505010903049',
    _dpd_extranet_page => $web_page,    # only for testing so that we don't fetch live
);
is($dpd_parcel->pick_up_datetime, '2013-12-13T16:08:00', 'pick_up_datetime()');
is($dpd_parcel->deliver_datetime, '2013-12-18T09:54:00', 'deliver_datetime()');
is($dpd_parcel->country, 'NL', 'country()');
is($dpd_parcel->city, 'Veenendaal', 'city()');
is($dpd_parcel->zip, '3565NL', 'zip()');

is_deeply(
    $dpd_parcel->dpd_extranet_data,
    {
        places => [
            {
              'depot' => '0650',
              'city' => 'Bratislava',
              'zip' => '3565NL',
              'country' => 'NL',
              'date' => '2013-12-13T16:08:00',
              'code' => [
                          '101'
                        ],
              'route' => '0511',
              'scan_type' => 'Pick-up',
              'tour' => '12'
            },
            {
              'country' => 'NL',
              'zip' => '3565NL',
              'city' => 'Kesselsdorf',
              'depot' => '0101',
              'tour' => '650',
              'scan_type' => 'Consolidation',
              'code' => [
                          '101'
                        ],
              'route' => '0511',
              'date' => '2013-12-16T14:01:00'
            },
            {
              'scan_type' => 'Hub scan',
              'code' => [
                          '101'
                        ],
              'route' => '0511',
              'date' => '2013-12-17T02:53:00',
              'tour' => '15',
              'depot' => '0015',
              'country' => 'NL',
              'zip' => '3565NL',
              'city' => 'Unna'
            },
            {
              'country' => 'NL',
              'zip' => '3565NL',
              'city' => 'Veenendaal',
              'depot' => '0511',
              'tour' => '399',
              'scan_type' => 'Inbound',
              'route' => '0511',
              'code' => [
                          '101'
                        ],
              'date' => '2013-12-18T05:32:00'
            },
            {
              'tour' => '164',
              'code' => [
                          '101'
                        ],
              'route' => '0511',
              'scan_type' => 'Out for delivery',
              'date' => '2013-12-18T06:32:00',
              'country' => 'NL',
              'city' => 'Veenendaal',
              'zip' => '3565NL',
              'depot' => '0511'
            },
            {
              'date' => '2013-12-18T06:32:00',
              'route' => '0511',
              'code' => [
                          '101'
                        ],
              'scan_type' => 'Out for delivery',
              'tour' => '164',
              'depot' => '0511',
              'zip' => '3565NL',
              'city' => 'Veenendaal',
              'country' => 'NL'
            },
            {
              'scan_type' => 'Delivered to: A COLLARD',
              'code' => [
                          '101'
                        ],
              'route' => '0511',
              'date' => '2013-12-18T09:54:00',
              'tour' => '164',
              'depot' => '0511',
              'country' => 'NL',
              'city' => 'Veenendaal',
              'zip' => '3565NL'
            }
          ],
    },
    'dpd_extranet_data()'
);

done_testing();
