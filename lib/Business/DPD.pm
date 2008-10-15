package Business::DPD;

use strict;
use warnings;
use 5.010;

use version; our $VERSION = version->new('0.01');

=head1 NAME

Business::DPD - generate DPD label information

=head1 SYNOPSIS

  use Business::DPD;

=head1 DESCRIPTION

Business::DPD is

=head1 METHODS

=head2 Public Methods

=cut


=head1 TODO

* ROUTES-DB in code packen
* mapping country->country number

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
