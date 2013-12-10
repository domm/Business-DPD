use 5.010;
use strict;
use warnings;

use Test::Most;
use Encode;
use Path::Class;
use FindBin '$Bin';
use DateTime;
use utf8;

use_ok('Business::DPD::DataExchange::mpsexpdata');
use_ok('Business::DPD::Address');
use_ok('Business::DPD::Label');
use_ok('Business::DPD');

my $mpsexpdata_minimal = 'MPSEXPDATA_DelisID_CUST_0176_D20061123T154215';
my $mpsexpdata_multi = 'MPSEXPDATA_DelisID_CUST_0176_D20061124T154215';

my $dpd = Business::DPD->new;
$dpd->connect_schema;
$dpd->set_originator_address({
    name1   => 'DELICom DPD GmbH',
    street  => 'Wailandtstrasse 1',
    postal  => '63741',
    city    => 'Aschaffenburg',
    country => 'DE',
    phone   => '06021/ 0815',
    fax     => '06021/ 0816',
    email   => 'test.dpd@dpd.com',
    depot   => '0176',
});

FILE1_GENERATION: {
    my $label = Business::DPD::Label->new( $dpd, {
        address => Business::DPD::Address->new($dpd, {
            name1   => 'Hans Mustermann GmbH',
            street  => 'Musterstr. 12a',
            postal  => '63741',
            city    => 'Aschaffenburg',
            country => 'DE',
            phone   => '06021/112',
        }),
        serial          => '9700001008',
        service_code    => '101',
        reference_number => 'Testpaket',
        weight_g        => 5000, # 5kg

    });
    my $mpsexpdata = Business::DPD::DataExchange::mpsexpdata->new({
        delisid        => 'DelisID',
        customer_id    => '67899999999',
        customer_subid => '005',
        consecutive_no => 4,
        labels         => [$label],
        now            => DateTime->new(
            year   => 2006,
            month  => 11,
            day    => 23,
            hour   => 15,
            minute => 42,
            second => 15,
        ),
    });
    is($mpsexpdata->filename,$mpsexpdata_minimal, 'filename()');
    eq_or_diff_lines(
        $mpsexpdata->as_string,
        ''.file($Bin,$mpsexpdata_minimal)->slurp,
        'as_string()',
    );
}

FILE2_GENERATION: {
    my $label1 = Business::DPD::Label->new( $dpd, {
        address => Business::DPD::Address->new($dpd, {
            name1   => 'Hans Mustermann GmbH',
            street  => 'Musterstr. 12a',
            postal  => '63741',
            city    => 'Aschaffenburg',
            country => 'DE',
            phone   => '06021/112',
        }),
        serial          => '9700001009',
        service_code    => '101',
        shipment_count_this => 1,
        shipment_count_total => 2,
        reference_number => 'Testpaket',
        weight_g    => 5000, # 5kg
    });
    my $label2 = Business::DPD::Label->new( $dpd, {
        address => Business::DPD::Address->new($dpd, {
            name1   => 'Hans Mustermann GmbH',
            street  => 'Musterstr. 12a',
            postal  => '63741',
            city    => 'Aschaffenburg',
            country => 'DE',
            phone   => '06021/112',
        }),
        serial          => '9700001010',
        service_code    => '101',
        shipment_count_this => 2,
        shipment_count_total => 2,
        reference_number => 'Testpaket2',
        weight_g    => 6000, # 6kg

    });
    my $label3 = Business::DPD::Label->new( $dpd, {
        address => Business::DPD::Address->new($dpd, {
            name1   => 'Hans Mustermann GmbH',
            street  => 'AndereMusterstr. 1b',
            postal  => '63741',
            city    => 'Aschaffenburg',
            country => 'DE',
            phone   => '06021/112',
        }),
        serial          => '9700001011',
        service_code    => '101',
        shipment_count_this => 1,
        shipment_count_total => 1,
        reference_number => 'Testpaket3',
        weight_g    => 1000, # 1kg

    });
    my $mpsexpdata = Business::DPD::DataExchange::mpsexpdata->new({
        delisid        => 'DelisID',
        customer_id    => '67899999999',
        customer_subid => '005',
        consecutive_no => 4,
        labels         => [$label2,$label1,$label3],
        now            => DateTime->new(
            year   => 2006,
            month  => 11,
            day    => 24,
            hour   => 15,
            minute => 42,
            second => 15,
        ),
    });
    is($mpsexpdata->filename,$mpsexpdata_multi, 'filename()');
    eq_or_diff_lines(
        $mpsexpdata->as_string,
        ''.file($Bin,$mpsexpdata_multi)->slurp,
        'as_string()',
    );
}

FILE2_PARSING: {
    my @data = Business::DPD::DataExchange::mpsexpdata->parse_to_data(''.file($Bin,$mpsexpdata_multi)->slurp);
    is_deeply(
        \@data,
        [
          {
            'type' => 'HEADER',
            'attrs' => {
                         'MPSWEIGHT' => '1100',
                         'UMVERREF' => '',
                         'SILN' => '',
                         'MPSCREF3' => '',
                         'MPSVOLUME' => '',
                         'RCITY' => 'Aschaffenburg',
                         'SHOUSENO' => '',
                         'CDATE' => '',
                         'RCOMMENT' => '',
                         'RDEPOT' => '',
                         'SCOUNTRYN' => '276',
                         'SEMAIL' => 'test.dpd@dpd.com',
                         'RSTREET' => 'Musterstr. 12a',
                         'SCOMMENT' => '',
                         'RHOUSENO' => '',
                         'MPSCOMPLBL' => '0',
                         'RCOUNTRYN' => '276',
                         'MPSCREF4' => '',
                         'RNAME2' => '',
                         'ESORT' => '',
                         'MPSID' => 'MPS0176970000100920061124',
                         'RCUSTID' => '',
                         'MPSCOMP' => '1',
                         'CUSER' => '',
                         'LATEPICKUP' => '0',
                         'MPSSTIME' => '',
                         'RPOSTAL' => '63741',
                         'MPSCREF2' => '',
                         'SPHONE' => '06021/ 0815',
                         'RPHONE' => '06021/112',
                         'SCUSTSUBID' => '005',
                         'SPOSTAL' => '63741',
                         'PODMAN' => '0',
                         'MPSSDATE' => '',
                         'RFAX' => '',
                         'CTIME' => '',
                         'SNAME2' => '',
                         'DELISUSR' => 'DelisID',
                         'SCITY' => 'Aschaffenburg',
                         'MPSSERVICE' => '101',
                         'UMVER' => '0',
                         'REMAIL' => '',
                         'MPSCREF1' => 'Testpaket',
                         'HARDWARE' => 'K',
                         'SDEPOT' => '0176',
                         'RILN' => '',
                         'SCONTACT' => '',
                         'RNAME1' => 'Hans Mustermann GmbH',
                         'SCUSTID' => '67899999999',
                         'MPSCOUNT' => '2',
                         'RSTATE' => '',
                         'SNAME1' => 'DELICom DPD GmbH',
                         'SFAX' => '06021/ 0816',
                         'SSTREET' => 'Wailandtstrasse 1',
                         'RCONTACT' => ''
                       }
          },
          {
            'attrs' => {
                         'MPSID' => 'MPS0176970000100920061124',
                         'HINSCURRENCY' => '',
                         'DELISUSR' => 'DelisID',
                         'VOLUME' => '',
                         'CREF4' => '',
                         'HINSURE' => '0',
                         'PARCELNO' => '01769700001009',
                         'WEIGHT' => '500',
                         'CREF1' => 'Testpaket',
                         'HINSAMOUNT' => '0',
                         'HINSCONTENT' => '',
                         'CREF2' => '',
                         'CREF3' => '',
                         'SERVICE' => '101'
                       },
            'type' => 'PARCEL'
          },
          {
            'attrs' => {
                         'CREF3' => '',
                         'SERVICE' => '101',
                         'CREF2' => '',
                         'HINSAMOUNT' => '0',
                         'HINSCONTENT' => '',
                         'CREF1' => 'Testpaket2',
                         'HINSURE' => '0',
                         'WEIGHT' => '600',
                         'PARCELNO' => '01769700001010',
                         'HINSCURRENCY' => '',
                         'VOLUME' => '',
                         'CREF4' => '',
                         'DELISUSR' => 'DelisID',
                         'MPSID' => 'MPS0176970000100920061124'
                       },
            'type' => 'PARCEL'
          },
          {
            'attrs' => {
                         'MPSCOMP' => '1',
                         'CUSER' => '',
                         'MPSCREF4' => '',
                         'ESORT' => '',
                         'RNAME2' => '',
                         'RCUSTID' => '',
                         'MPSID' => 'MPS0176970000101120061124',
                         'RHOUSENO' => '',
                         'RCOUNTRYN' => '276',
                         'MPSCOMPLBL' => '0',
                         'SCOUNTRYN' => '276',
                         'SEMAIL' => 'test.dpd@dpd.com',
                         'RSTREET' => 'AndereMusterstr. 1b',
                         'SCOMMENT' => '',
                         'CDATE' => '',
                         'RCOMMENT' => '',
                         'RDEPOT' => '',
                         'MPSVOLUME' => '',
                         'RCITY' => 'Aschaffenburg',
                         'SHOUSENO' => '',
                         'MPSCREF3' => '',
                         'MPSWEIGHT' => '100',
                         'UMVERREF' => '',
                         'SILN' => '',
                         'SSTREET' => 'Wailandtstrasse 1',
                         'RCONTACT' => '',
                         'SNAME1' => 'DELICom DPD GmbH',
                         'SFAX' => '06021/ 0816',
                         'SCONTACT' => '',
                         'RNAME1' => 'Hans Mustermann GmbH',
                         'SCUSTID' => '67899999999',
                         'MPSCOUNT' => '1',
                         'RSTATE' => '',
                         'MPSCREF1' => 'Testpaket3',
                         'HARDWARE' => 'K',
                         'SDEPOT' => '0176',
                         'RILN' => '',
                         'UMVER' => '0',
                         'MPSSERVICE' => '101',
                         'REMAIL' => '',
                         'SNAME2' => '',
                         'DELISUSR' => 'DelisID',
                         'SCITY' => 'Aschaffenburg',
                         'SPHONE' => '06021/ 0815',
                         'SCUSTSUBID' => '005',
                         'RPHONE' => '06021/112',
                         'PODMAN' => '0',
                         'RFAX' => '',
                         'MPSSDATE' => '',
                         'CTIME' => '',
                         'SPOSTAL' => '63741',
                         'LATEPICKUP' => '0',
                         'MPSSTIME' => '',
                         'MPSCREF2' => '',
                         'RPOSTAL' => '63741'
                       },
            'type' => 'HEADER'
          },
          {
            'type' => 'PARCEL',
            'attrs' => {
                         'MPSID' => 'MPS0176970000101120061124',
                         'PARCELNO' => '01769700001011',
                         'CREF1' => 'Testpaket3',
                         'CREF2' => '',
                         'CREF3' => '',
                         'CREF4' => '',
                         'DELISUSR' => 'DelisID',
                         'SERVICE' => '101',
                         'VOLUME' => '',
                         'WEIGHT' => '100',
                         'HINSURE' => '0',
                         'HINSAMOUNT' => '0',
                         'HINSCURRENCY' => '',
                         'HINSCONTENT' => '',
                       }
          }
        ],
        'parse_to_data()',
    );
}

done_testing;


sub eq_or_diff_lines {
    my ($is,$expected,$description) = @_;

    return if ok($is eq $expected, $description);

    my @is_lines = split("\n", $is);
    my @expected_lines = split("\n", $expected);
    my $max_lines = @expected_lines > @is_lines ? @expected_lines : @is_lines;
    for my $i (1..$max_lines) {
        my $is_line = $is_lines[$i] // '---- line missing ----';
        my $expected_line = $expected_lines[$i] // '---- line missing ----';
        if ($is_line ne $expected_line) {
            diag $i, " is: ", $is_line;
            diag $i, " ex: ", $expected_line;
        }
    };

}
