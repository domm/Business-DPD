use 5.010;
use strict;
use warnings;

#use Test::More tests => 4;
#use Test::NoWarnings;

use Business::DPD;
use Business::DPD::Label;
use Business::DPD::Render::PDFReuse;
my $dpd = Business::DPD->new;
$dpd->connect_schema;
my $label = Business::DPD::Label->new($dpd,{
    zip             => '12555',
    country         => 'DE',
    depot           => '0190',
    serial          => '5002345615',
    service_code    => '101',
});

$label->calc_fields;

my $renderer = Business::DPD::Render::PDFReuse->new($dpd,{
    outdir => '.',    
    originator => ['some','lines','of text'],
    template=>'lab/template3.pdf',
});

$renderer->render($label);
