use 5.010;
use strict;
use warnings;

use Test::More tests => 2;
use Encode;
use utf8;
eval {
    use Business::DPD;
    use Business::DPD::Label;
    use Business::DPD::Render::PDFReuse::SlimA6;
    my $dpd = Business::DPD->new;
    $dpd->connect_schema;
    my $label = Business::DPD::Label->new($dpd,{
        zip             => '12555',
        country         => 'DE',
        depot           => '0190',
        serial          => '5002345615',
        service_code    => '101',
        weight          => '23,45 KG',
        shipment_count_this=>1,
        shipment_count_total=>2,
        reference_number=>"foobar",
        order_number=>["aaa","bbb","ccc"],
        recipient=> ['Klinikum Stadt Hanau','Wöchnerinnenstation H5','Frau Sabine Leue','Leimstr. 20','DE-1255 Hanau'],
    });

    $label->calc_fields;

    my $renderer = Business::DPD::Render::PDFReuse::SlimA6->new($dpd,{
        outdir => '.',    
        originator=>['babilu Service','Present Service Ullrich GmbH + Co.KG','Wetterkreuz 11','91058 Erlangen'],
        template=>'templates/default.pdf',
    });

    $renderer->render($label);
};

is($@,'','no error');
ok(-e '001255501905002345615101276.pdf','pdf exists');
unlink('001255501905002345615101276.pdf') unless $ENV{KEEP_PDF};

