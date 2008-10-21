package Business::DPD::Render::PDFReuse;

use strict;
use warnings;
use 5.010;

use parent qw(Business::DPD::Render);
use Carp;
use PDF::Reuse;
use PDF::Reuse::Barcode;

__PACKAGE__->mk_accessors(qw(template));

=head1 NAME

Business::DPD::Render - render a lable

=head1 SYNOPSIS

    use Business::DPD::Render::SomeSubclass;
    my $renderer = Business::DPD::Render::SomeSubclass->new( $dpd, {
        outdir => '/path/to/output/dir/',    
        originator => ['some','lines','of text'],
    });
    my $path = $renderer->render( $label );

=head1 DESCRIPTION

You should really use a subclass of this module!

=head1 METHODS

=head2 Public Methods

=cut

sub render {
    my ( $self, $label ) = @_;

    my $code_hr = $label->code_human;

    die unless $self->template;
    say $self->template;

    prFile( $code_hr . '.pdf' );
    prMbox( 0, 0, 257, 420 );
    prForm( {
            file => $self->template,
            page => 1,
            x    => 0,
            y    => 0
        }
    );

    PDF::Reuse::Barcode::Code128(
        mode           => 'graphic',
        x              => 20,
        text           => 0,
        ySize          => 3,
        xSize          => 0.9,
        y              => -5,
        drawBackground => 0,
        value          => chr(0xf5) . $label->code_barcode
    );

    prTTFont ( "MONACO.TTF" );
    # barcode
    prFontSize(9);
    prText( 126, 12, $label->code_human, 'center' );

    # tracking number
    prFontSize(26);
    prText( 8, 174, $label->depot );
    prFontSize(20);
    prText( 72, 174, $label->serial );
    prFontSize(14);
    prText( 195, 174, $label->checksum_tracking_number );

    # Label-Ursprug
    prFontSize(4);
    prText( 126, 89, "TODO!! 2008-10-21 16:16; ROUTEVER; Business-DPD-0.01",
        'center' );

    # Servicecode-Land-EmpfaengerPLZ
    prFontSize(9);
    prText( 126, 98,
        join( '-', $label->service_code, $label->country, $label->zip ),
        'center' );

    # routing
    prFontSize(28);
    prText( 20,  95, $label->o_sort );
    prText( 237, 95, $label->d_sort,'right' );
    if ( $label->route_code ) {
        prFontSize(34);
        prText(
            126,
            130,
            $label->country . '-'
                . $label->d_depot . '-'
                . $label->route_code,
            'center'
        );
    }
    else {
        prFontSize(40);
        prText( 126, 130, $label->country . '-' . $label->d_depot, 'center' );
    }

    # depot info
    #my $depot = $self->_dpd->schema->resultset('Depot')
    prFontSize(12);
    prText( 230, 390, "TODO DEPOT INFO",'',270 );
    prText( 200, 390, "TODO ABSENDER INFO",'',270 );
    prText( 20, 380, "TODO RECEIVER INFO", );

    prEnd();

}

1;

__END__

=head1 AUTHOR

RevDev E<lt>we {at} revdev.atE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
