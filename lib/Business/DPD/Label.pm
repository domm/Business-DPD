package Business::DPD::Label;

use strict;
use warnings;
use 5.010;

use parent qw(Class::Accessor::Fast);
use Carp;

# input data
__PACKAGE__->mk_accessors(qw(zip country depot serial service_code));

# calculated values
__PACKAGE__->mk_accessors(qw(_fields_calculated tracking_number o_sort d_sort target_depot target_country route_code));

# internal
__PACKAGE__->mk_accessors(qw(_dpd));



=head1 NAME

Business::DPD::Label - one DPD label

=head1 SYNOPSIS

    use Business::DPD::Label;
    my $label = Business::DPD::Label->new( $dpd, {
        zip             => '12555',
        country         => 'DE',
        depot           => '1090',
        serial          => '5012345678',
        service_code    => '101',    
    });
    $label->calc_fields;
    say $label->tracking_number;
    say $label->d_sort;


=head1 DESCRIPTION

TODO

=head1 METHODS

=head2 Public Methods

=cut

=head3 new

    my $label = Business::DPD::Label->new( $dpd, {
        zip             => '12555',
        country         => 'DE',
        depot           => '1090',
        serial          => '5012345678',
        service_code    => '101',
    });

TODO: take a Business::DPD::Address as an agrument (instead of zip & country)

=cut

sub new {
    my ($class, $dpd, $opts) = @_;

    # check required params
    my @missing;
    foreach (qw(zip country depot serial service_code)) {
        push(@missing, $_) unless $opts->{$_};
    }
    croak "required option ".join(',',map{"'$_'"}@missing)." missing" if @missing;

    # validata some params
    croak "'country' must be uppercase two letter ISO code (eg 'DE')" unless $opts->{country}=~/^[A-Z][A-Z]$/;
    croak "'depot' must be 4 digits (eg '1090')" unless $opts->{depot} =~ /^\d{4}$/;
    croak "'serial' must be 10 digits (eg '5012345678')" unless $opts->{serial} =~ /^\d{10}$/;
    croak "'service_code' must be 4 digits (eg '1090')" unless $opts->{service_code} =~ /^\d{3}$/;

    my $self = bless $opts, $class;
    $self->_dpd($dpd);
    return $self;
}

=head3 calc_fields

    $label->calc_fields;

Calculate the following fields from the provided data using the DPD database from C<$schema>:

  tracking_number o_sort d_sort target_depot target_country route_code

=cut

sub calc_fields {
    my $self = shift;

    $self->calc_tracking_number;
    $self->calc_routing;
    $self->_fields_calculated(1);
}

=head3 calc_tracking_number

    $label->calc_tracking_number;

Calulates the tracking number and stores it in C<tracking_number>. C<tracking_number> consists of 

   DDDDXXLLLLLLLLP
      | |     |  |
      | |     |  +-> iso7064_mod37_36_checksum      L
      | |     +----> serial                         12345678
      | +----------> first two positions of serial  50
      +------------> depot                          1090


=cut

sub calc_tracking_number {
    my $self = shift;

    my $base = $self->depot . $self->serial;
    my $checksum = $self->_dpd->iso7064_mod37_36_checksum($base);
    $self->tracking_number($base . $checksum);
}
    

sub calc_routing {
    my ( $self, $schema ) = @_;
}

=head1 TODO

=head3 Routenfeld

* tracking number:

input: depot number (plus 5+6 stelle?), laufende nummer
output: tracking number incl checksum

* routing:

input: target zip, Land,
output: O-Sort, Land, Empfangsdepot, Beförderungsweg, D-Sort

* weiters:

kennzeichnung (kleingewicht, Express)
Servicetext
Servicecode

Lableursprung( datum/zeit, routenDB version, software)

=head3 Barcodefeld

input: target zip, tracking number, servicecode, target country number
output: barcode-number incl checksum, barcode image

=head3 Sendungsinformationsfeld

input: adressdaten

=cut

=head1 needed methods

* one object for one address
* required fields
** target country
** target zipcode
** laufende nummer
** depot number
** service code
* semi-required
** address data
* optional
** referenznummer
** auftragsnummer
** gewicht
** n of m
** template

=cut

1;

__END__

=head1 AUTHOR

RevDev E<lt>we {at} revdev.atE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
