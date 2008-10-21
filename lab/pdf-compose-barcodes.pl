use PDF::Reuse;
use PDF::Reuse::Barcode;



prFile('page.pdf');

prForm(  { file =>'../001255501905002345615101276Z.pdf',
                    page => 1,
                    x    => 500,
                    rotate => 90,
                    y    => 20} );

prForm(  { file =>'template3.pdf',
                    page => 1,
                    x    => 500,
                    rotate => 90,
                    y    => 290} );

prForm(  { file =>'template3.pdf',
                    page => 1,
                    x    => 500,
                    rotate => 90,
                    y    => 560} );

  prEnd();

=cut

prFile('bars2.pdf');
prMbox(0,0,3*72,120);

  PDF::Reuse::Barcode::Code128(
  mode=>'graphic',
  x     => 0,
  text=>0,
  ySize=>3,
  xSize=>0.9,
  y     => 0,
  drawBackground=>0,
value=>  chr(0xf5).'%007110601782532948375101276'                            
                );
  
  prFont('Times-Roman');     # Just setting a font
   prFontSize(10);
   prText(0,0, "00711 0601782532948375 101 276 O");

  
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


