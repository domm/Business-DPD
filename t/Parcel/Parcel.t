use 5.010;
use strict;
use warnings;
use utf8;

use Test::Most 0.02;

use Path::Class qw(file);
use FindBin '$Bin';

use Business::DPD::Parcel;

binmode(STDOUT, ':encoding(UTF-8)');

if ($ENV{DO_LIVE_TEST}) {
    my $dpd_parcel_nonexists = Business::DPD::Parcel->new(tracking_number => '06505010903049');
    ok($dpd_parcel_nonexists->dpd_tracking_data_string, 'fetch tracking data');
    is($dpd_parcel_nonexists->exists, 0, 'parcel does not exist');

    my $dpd_parcel = Business::DPD::Parcel->new(tracking_number => '06505024408942');
    ok($dpd_parcel->dpd_tracking_data_string, 'fetch tracking data');
}

{
    my $dpd_parcel = Business::DPD::Parcel->new(
        tracking_number           => '06505024408942',
        _dpd_tracking_data_string => '
    {
	"ErrorJSON":	{
		"code":	-2,
		"message":	"We\'re sorry but the parcel label number you have entered is not valid. Please check your entry once more. "
	}
}'
    );
    warning_like { $dpd_parcel->dpd_tracking_data } qr/failed to fetch/, 'warning given for failed request';
    is ($dpd_parcel->exists,           0,     'parcel does not exist');
    is($dpd_parcel->pick_up_datetime, undef, 'pick_up_datetime()');
    is($dpd_parcel->delivery_datetime, undef, 'delivery_datetime()');
    is($dpd_parcel->current_country,          undef, 'country()');
    is($dpd_parcel->current_city,             undef, 'city()');
    dies_ok {$dpd_parcel->zip} 'zip no longer available';
}

{
    my $json = file($Bin, 'tracing01.json')->slurp;
    my $dpd_parcel = Business::DPD::Parcel->new(
        tracking_number           => '06505024408942',
        _dpd_tracking_data_string => $json,           # only for testing so that we don't fetch live
    );

    is($dpd_parcel->exists,           1,                     'parcel exists');
    is($dpd_parcel->pick_up_datetime, '2016-11-22T15:33:00', 'pick_up_datetime()');
    is($dpd_parcel->delivery_datetime, '2016-11-28T11:15:00', 'delivery_datetime()');
    is($dpd_parcel->current_country,          'NL',                  'country()');
    is($dpd_parcel->current_city,             'AMSTERDAM',           'city()');
    is_deeply(
        $dpd_parcel->dpd_tracking_data,
        {   'TrackingStatusJSON' => {
                'shipmentInfo' => {
                    'podUrl' =>
                        '//tracking.dpd.de/cgi-bin/delistrack.acl?typ=7&lang=en&pknr=06505024408942&var=0516|2811|7000022|2016|998|E||',
                    'codInformationAvailable' => 0,
                    'product'                 => 'DPD CLASSIC',
                    'receiverAvailable'       => 1,
                    'deliveryStatusMessage' => 'Your parcel was delivered on 28/11/2016, at 11:15 ',
                    'receiverPostCodeMismatch' => 0,
                    'receiverPostCode'         => '',
                    'deliveryStatusIcons'      => [4, 5, 6, 9, 10],
                    'showFollowMyParcel'       => 0,
                    'destinationCountry'       => 'NL',
                    'parcelNumber'             => '06505024408942',
                    'receiver'                 => '',
                    'isReturnToSender'         => 0,
                    'deliveryStatus'           => 5,
                    'checkSum'                 => 'K'
                },
                'statusInfos' => [
                    {   'parcelNumber'                => '',
                        'depotNr'                     => '0998',
                        'date'                        => '22/11/2016',
                        'time'                        => '13:44 ',
                        'showDepotContactInformation' => 0,
                        'city'                        => 'DPD data centre',
                        'detailLevel'                 => 0,
                        'contents'                    => [
                            {   'detailLevel' => 0,
                                'label'       => 'Order information has been transmitted to DPD.',
                                'contentType' => 'text'
                            }
                        ]
                    },
                    {   'depotNr'                     => '0650',
                        'date'                        => '22/11/2016',
                        'city'                        => 'Bratislava (SK)',
                        'time'                        => '15:33 ',
                        'showDepotContactInformation' => 0,
                        'parcelNumber'                => '',
                        'contents'                    => [
                            {   'contentType' => 'text',
                                'label'       => 'Received by DPD from consignor.',
                                'detailLevel' => 0
                            }
                        ],
                        'detailLevel' => 0
                    },
                    {   'detailLevel' => 0,
                        'contents'    => [
                            {   'detailLevel' => 0,
                                'contentType' => 'text',
                                'label'       => 'In transit.'
                            }
                        ],
                        'parcelNumber'                => '',
                        'showDepotContactInformation' => 1,
                        'time'                        => '17:59 ',
                        'city'                        => 'Bratislava (SK)',
                        'depotNr'                     => '0650',
                        'date'                        => '22/11/2016'
                    },
                    {   'date'                        => '23/11/2016',
                        'depotNr'                     => '0101',
                        'time'                        => '14:06 ',
                        'city'                        => 'Kesselsdorf (DE)',
                        'showDepotContactInformation' => 0,
                        'parcelNumber'                => '',
                        'contents'                    => [
                            {   'contentType' => 'text',
                                'label'       => 'In transit.',
                                'detailLevel' => 0
                            }
                        ],
                        'detailLevel' => 1
                    },
                    {   'detailLevel' => 1,
                        'contents'    => [
                            {   'label'       => 'In transit.',
                                'contentType' => 'text',
                                'detailLevel' => 0
                            },
                            {   'detailLevel' => 0,
                                'label'       => 'Preload.',
                                'contentType' => 'text'
                            }
                        ],
                        'parcelNumber'                => '',
                        'date'                        => '24/11/2016',
                        'depotNr'                     => '0015',
                        'time'                        => '02:26 ',
                        'city'                        => 'Unna (DE)',
                        'showDepotContactInformation' => 0
                    },
                    {   'parcelNumber'                => '',
                        'city'                        => 'AMSTERDAM (NL)',
                        'time'                        => '07:56 ',
                        'showDepotContactInformation' => 0,
                        'depotNr'                     => '0516',
                        'date'                        => '25/11/2016',
                        'detailLevel'                 => 0,
                        'contents'                    => [
                            {   'detailLevel' => 0,
                                'label'       => 'At parcel delivery centre.',
                                'contentType' => 'text'
                            }
                        ]
                    },
                    {   'detailLevel' => 0,
                        'contents'    => [
                            {   'label'       => 'Out for delivery.',
                                'contentType' => 'text',
                                'detailLevel' => 0
                            }
                        ],
                        'parcelNumber'                => '',
                        'city'                        => 'AMSTERDAM (NL)',
                        'time'                        => '09:05 ',
                        'showDepotContactInformation' => 0,
                        'depotNr'                     => '0516',
                        'date'                        => '25/11/2016'
                    },
                    {   'detailLevel' => 0,
                        'contents'    => [
                            {   'detailLevel' => 0,
                                'contentType' => 'text',
                                'label' =>
                                    'Unfortunately we have not been able to deliver your parcel.'
                            },
                            {   'label'       => 'Parcelshop delivery after 1st delivery attempt',
                                'contentType' => 'text',
                                'detailLevel' => 0
                            }
                        ],
                        'parcelNumber'                => '',
                        'city'                        => 'AMSTERDAM (NL)',
                        'time'                        => '12:04 ',
                        'showDepotContactInformation' => 0,
                        'date'                        => '25/11/2016',
                        'depotNr'                     => '0516'
                    },
                    {   'depotNr'                     => '0998',
                        'date'                        => '25/11/2016',
                        'time'                        => '12:04 ',
                        'showDepotContactInformation' => 0,
                        'city'                        => 'DPD data centre',
                        'parcelNumber'                => '',
                        'contents'                    => [
                            {   'detailLevel' => 0,
                                'contentType' => 'text',
                                'label'       => 'Redirected to the following Pickup parcelshop:'
                            },
                            {   'detailLevel' => 0,
                                'content' =>
                                    '<div class="parcel-shop-details">    <div class="modal-head">        <span>Details of your Pickup parcelshop</span>    </div>    <div class="modal-inner">            <div class="company-name">ETOS WIND</div>        <div class="address-contact">            <div class="address">VAN WOUSTRAAT 81<br />1074AD&nbsp;Amsterdam (NL)</div>            <div class="contact"><table><tbody></table></tbody></div>            <hr>            <div class="mail"></div>        </div>        <div class="opening-hours">            <span>Opening hours</span>            <table><tbody><tr><td >Mo.:</td><td>09:00-12:00&nbsp;</td><td>12:00-18:00&nbsp;</td></tr><tr><td >Tu.:</td><td>09:00-12:00&nbsp;</td><td>12:00-18:00&nbsp;</td></tr><tr class="current"><td >We.</td><td>09:00-12:00&nbsp;</td><td>12:00-18:00&nbsp;</td></tr><tr><td >Th.:</td><td>09:00-12:00&nbsp;</td><td>12:00-18:00&nbsp;</td></tr><tr><td >Fr.:</td><td>09:00-12:00&nbsp;</td><td>12:00-18:00&nbsp;</td></tr><tr><td >Sa.:</td><td>09:00-12:00&nbsp;</td><td>12:00-17:30&nbsp;</td></tr><tr><td >Su.:</td><td colspan="2">closed</td></tr></tbody></table>        </div>    </div></div>',
                                'contentType' => 'modal',
                                'label'       => 'ETOS WIND'
                            }
                        ],
                        'detailLevel' => 0
                    },
                    {   'parcelNumber'                => '',
                        'showDepotContactInformation' => 0,
                        'city'                        => 'AMSTERDAM (NL)',
                        'time'                        => '13:06 ',
                        'date'                        => '25/11/2016',
                        'depotNr'                     => '0516',
                        'detailLevel'                 => 0,
                        'contents'                    => [
                            {   'detailLevel' => 0,
                                'contentType' => 'text',
                                'label'       => 'Delivered by driver to Pickup parcelshop.'
                            },
                            {   'detailLevel' => 0,
                                'contentType' => 'link',
                                'label'       => 'evidence',
                                'url' =>
                                    '//tracking.dpd.de/cgi-bin/delistrack.acl?typ=7&lang=en&pknr=06505024408942&var=0516|2511|6733790|2016|998|E||'
                            },
                            {   'detailLevel' => 0,
                                'content' =>
                                    '<div class="parcel-shop-details">    <div class="modal-head">        <span>Details of your Pickup parcelshop</span>    </div>    <div class="modal-inner">            <div class="company-name">ETOS WIND</div>        <div class="address-contact">            <div class="address">VAN WOUSTRAAT 81<br />1074AD&nbsp;Amsterdam (NL)</div>            <div class="contact"><table><tbody></table></tbody></div>            <hr>            <div class="mail"></div>        </div>        <div class="opening-hours">            <span>Opening hours</span>            <table><tbody><tr><td >Mo.:</td><td>09:00-12:00&nbsp;</td><td>12:00-18:00&nbsp;</td></tr><tr><td >Tu.:</td><td>09:00-12:00&nbsp;</td><td>12:00-18:00&nbsp;</td></tr><tr class="current"><td >We.</td><td>09:00-12:00&nbsp;</td><td>12:00-18:00&nbsp;</td></tr><tr><td >Th.:</td><td>09:00-12:00&nbsp;</td><td>12:00-18:00&nbsp;</td></tr><tr><td >Fr.:</td><td>09:00-12:00&nbsp;</td><td>12:00-18:00&nbsp;</td></tr><tr><td >Sa.:</td><td>09:00-12:00&nbsp;</td><td>12:00-17:30&nbsp;</td></tr><tr><td >Su.:</td><td colspan="2">closed</td></tr></tbody></table>        </div>    </div></div>',
                                'label'       => 'ETOS WIND',
                                'contentType' => 'modal'
                            }
                        ]
                    },
                    {   'parcelNumber'                => '',
                        'date'                        => '28/11/2016',
                        'depotNr'                     => '0516',
                        'city'                        => 'AMSTERDAM (NL)',
                        'time'                        => '11:15 ',
                        'showDepotContactInformation' => 0,
                        'detailLevel'                 => 0,
                        'contents'                    => [
                            {   'detailLevel' => 0,
                                'label'       => 'Collected by consignee from Pickup parcelshop.',
                                'contentType' => 'text'
                            }
                        ]
                    }
                ]
            }
        },
        'dpd_tracking_data()'
    );
}

done_testing();
