use PDF::Reuse;
use PDF::Reuse::Barcode;


prFile('foobar.pdf');
prMbox ( 0,0,257,420 );
prForm(  { file =>'template3.pdf',
                    page => 1,
                    x    => 0,
                    y    => 0} );

PDF::Reuse::Barcode::Code128(
  mode=>'graphic',
  x     => 20,
  text=>0,
  ySize=>3,
  xSize=>0.9,
  y     => -5,
  drawBackground=>0,
value=>  chr(0xf5).'%007110601782532948375101276'                            
                );
  


prFont('Courier');     # Just setting a font
   prFontSize(9);
   prText(40,12, "00711 0601782532948375 101 276 O");

  
  prEnd();

=cut

__END__

HE01/%007110601782532948375101276
HE01/%007110601782532948375101276


HE01/%007110601782532948375101276

HE01/%001255501905002345614101276

HE01/%001255501905002345614101276


HE01/001255501905002345615101276Y
HE01/%003425301905002345615101276
HE01/%001255501905002345614101276
HE01/%007110601782532948375101276


