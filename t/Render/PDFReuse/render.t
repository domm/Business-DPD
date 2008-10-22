use 5.010;
use strict;
use warnings;

use Test::More tests => 2;

eval {
use Business::DPD;
use Business::DPD::Label;
use Business::DPD::Render::PDFReuse::SlimA6;
my $dpd = Business::DPD->new;
$dpd->connect_schema;
my $label = Business::DPD::Label->new($dpd,{
    zip             => '12555',
    city            => 'Hanau',
    country         => 'DE',
    depot           => '0190',
    serial          => '5002345615',
    service_code    => '101',
    weight          => '23,45 KG',
    shipment_count_this=>1,
    shipment_count_total=>2,
    recipient=> ['Klinikum Stadt Hanau','Wöchnerinnenstation H5','Frau Sabine Leue','Leimstr. 20'],
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
ok(-e '001255501905002345615101276Z.pdf','pdf exists');
unlink('001255501905002345615101276Z.pdf') unless $ENV{KEEP_PDF};

