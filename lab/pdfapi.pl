use strict;
use warnings;
use 5.010;
use PDF::API2;

use constant mm => 25.4 / 72;
use constant in => 1 / 72;
use constant pt => 1;

my $pdf = PDF::API2->new(-file=>'foo.pdf');
my $font = $pdf->corefont('Times-Roman');

my $page = $pdf->page;
$page->mediabox ("A6");
#$page->mediabox (105/mm, 148/mm);
#$page->cropbox  (7.5/mm, 7.5/mm, 97.5/mm, 140.5/mm);

my $code = '001255501905002345615101276';
my $code_checksum = '001255501905002345615101276Z';

my $box = $page->gfx;
my $bc = $pdf->xo_code128 (
    -type=>'c',
 #   -font => $font,    # a PDF $font set with $pdf->corefont
    -code => $code,    # a string we want encoded as a $bc xo form
    -quzn => 0,    # quiet zone, margin between bars and frame 
    -umzn => 0,    # upper mending zone size (10)
    -lmzn => 0,    # lower mending zone size (10) $lmzn sets the 
    #text font size of $code as rendered below bars
    -zone => 10/mm,    # bar height (20)
    -ofwt => 0.2,    # overflow weight, bar thickness (0.5)
    -fnsz => 0,    # font size (0) 
    -spcr => 0,    # spacer 
    #between elements (0)
  );
  # render $bc to page at x,y at 80%
$box->formimage($bc,10/mm,5/mm);

my $headline_text = $page->text;
$headline_text->font( $font, 10/pt );
$headline_text->fillcolor('black');
$headline_text->translate( 3/mm, 1/mm );
$headline_text->text($code_checksum);



$pdf->save;


