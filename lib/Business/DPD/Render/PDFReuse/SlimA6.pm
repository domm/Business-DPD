package Business::DPD::Render::PDFReuse::SlimA6;

use strict;
use warnings;
use 5.010;

use parent qw(Business::DPD::Render::PDFReuse);
use Carp;
use PDF::Reuse;
use PDF::Reuse::Barcode;
use Encode;
use DateTime;
use File::Spec::Functions qw(catfile);

=head1 NAME

Business::DPD::Render::PDFReuse::SlimA6 - render a lable in slim A6 using PDF::Reuse

=head1 SYNOPSIS

    use Business::DPD::Render::PDFReuse::SlimA6;
    my $renderer = Business::DPD::Render::PDFReuse::SlimA6->new( $dpd, {
        outdir => '/path/to/output/dir/',    
        originator => ['some','lines','of text'],
    });
    my $path = $renderer->render( $label );

=head1 DESCRIPTION

Render a DPD lable using a slim A6-based template that also fits on a 
A4-divided-by-three-page. This is what we need at the moment. If you 
want to provide other formats, please go ahead and either release them 
as a standalone dist on CPAN or contact me to include your design.

=head1 METHODS

=head2 Public Methods

=cut

=head3 render

    my $path_to_file = $renderer->render( $label );

Render the label. Currently there is nearly no error checking. Also, 
things might not fit into their boxes...

The finished PDF will be named C<$barcode.pdf> (i.e. without checksum or starting char)

=cut

sub render {
    my ( $self, $label, $y_offset ) = @_;
    $y_offset //=0;

    my $outfile = catfile($self->outdir,$label->code . '.pdf');

    $self->_begin_doc($label, $outfile, $y_offset);
    $self->_add_elements($label, $y_offset);
    $self->_end_doc($label, $y_offset);
    return $outfile;
}

sub _begin_doc {
    my ( $self, $label, $outfile, $y_offset ) = @_;
    
    prFile( $outfile );
    prMbox( 0, 0, 257, $y_offset+420 );
    prForm( {
            file => $self->template,
            page => 1,
            x    => 0,
            y    => $y_offset+0,
        }
    );
}

sub _add_elements {
    my ( $self, $label, $y_offset ) = @_;
    
    
    PDF::Reuse::Barcode::Code128(
        mode           => 'graphic',
        x              => 20,
        text           => 0,
        ySize          => 3,
        xSize          => 0.9,
        y              => $y_offset-5,
        drawBackground => 0,
        value          => chr(0xf5) . $label->code_barcode
    );

    my $font_path = $self->template;
    $font_path=~s/SlimA6.pdf/MONACO.TTF/;
    prTTFont($font_path);
    
    # barcode
    prFontSize(9);
    prText( 126, $y_offset+12, $label->code_human, 'center' );

    # tracking number
    prFontSize(26);
    prText( 8, $y_offset+174, $label->depot );
    prFontSize(20);
    prText( 72, $y_offset+174, $label->serial );
    prFontSize(14);
    prText( 195, $y_offset+174, $label->checksum_tracking_number );

    # Label-Ursprug
    prFontSize(4);
    my $now = DateTime->now;
    prText(
        126,
        $y_offset+89,
        join('; ',
            $now->strftime('%F %H:%M'),
            $self->_dpd->schema->resultset('DpdMeta')->search()->first->version,
            "Business-DPD-". Business::DPD->VERSION,
        ),
        'center'
    );

    # Servicecode-Land-EmpfaengerPLZ
    prFontSize(9);
    prText( 126, $y_offset+98,
        join( '-', $label->service_code, $label->country, $label->zip ),
        'center' );

    # routing
    prFontSize(28);
    prText( 20, $y_offset+95, $label->o_sort );
    prText( 237, $y_offset+95, $label->d_sort, 'right' );
    if ( $label->route_code ) {
        prFontSize(34);
        prText(
            126,
            $y_offset+130,
            $label->country . '-'
                . $label->d_depot . '-'
                . $label->route_code,
            'center'
        );
    }
    else {
        prFontSize(40);
        prText( 126, $y_offset+130, $label->country . '-' . $label->d_depot, 'center' );
    }

    # depot info
    my $depot
        = $self->_dpd->schema->resultset('DpdDepot')->find( $label->depot );
    my @dep = (
        $depot->name1, $depot->name2, $depot->address1, $depot->address2,
        $depot->country . '-' . $depot->postcode . ' ' . $depot->city
    );
    push( @dep, 'Tel: ' . $depot->phone ) if $depot->phone;
    push( @dep, 'Fax: ' . $depot->fax )   if $depot->fax;
    $self->_multiline(
        \@dep,
        {   fontsize => 4,
            base_x   => 250,
            base_y   => $y_offset+390,
            rotate   => '270',
        }
    );

    # originator{
    $self->_multiline(
        $self->originator,
        {   fontsize => 4,
            base_x   => 215,
            base_y   => $y_offset+385,
            rotate   => '270',
        }
    );

    # recipient
    $self->_multiline( $label->recipient,
        {   fontsize => 8,
            base_x   => 10,
            base_y   => $y_offset+386,
        }
    );

    # weight
    prFontSize(11);
    prText( 155, $y_offset+272, $label->weight, 'center' );

    # lieferung n / x
    my $count;
    if ( $label->shipment_count_this && $label->shipment_count_total ) {
        $count = $label->shipment_count_this . '/'
            . $label->shipment_count_total;
    }
    else {
        $count = '1/1';
    }
    prText( 155, $y_offset+295, $count, 'center' );

    # referenznr
    $self->_multiline( $label->reference_number,
        {   fontsize => 8,
            base_x   => 37,
            base_y   => $y_offset+308,
        }
    );

    # auftragsnr
    $self->_multiline( $label->order_number,
        {   fontsize => 8,
            base_x   => 37,
            base_y   => $y_offset+283,
        }
    );
}

sub _end_doc {
    my ( $self, $label ) = @_;

    prEnd();
}

sub template { shift->inc2pdf(__PACKAGE__) }

1;

__END__

=head1 AUTHOR

Thomas Klausner C<<domm {at} cpan.org>>
RevDev E<lt>we {at} revdev.atE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
