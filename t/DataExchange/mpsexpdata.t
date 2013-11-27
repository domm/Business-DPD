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
        reference_number => [ 'Testpaket' ],
        weight          => 5, # 5kg

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
        reference_number => [ 'Testpaket' ],
        weight          => 5, # 5kg

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
        reference_number => [ 'Testpaket2' ],
        weight          => 6, # 6kg

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
        reference_number => [ 'Testpaket3' ],
        weight          => 1, # 1kg

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
