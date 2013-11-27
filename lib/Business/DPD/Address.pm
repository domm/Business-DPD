package Business::DPD::Address;

use strict;
use warnings;
use 5.010;

use version; our $VERSION = version->new('0.22');

use parent qw(Class::Accessor::Fast);
use Carp;

# input data
__PACKAGE__->mk_accessors(qw(
    depot
    name1
    name2
    street
    houseno
    country
    state
    postal
    city
    contact
    phone
    fax
    email
    comment
    iln
));

# internal
__PACKAGE__->mk_accessors(qw(_dpd));

sub new {
    my ($class, $dpd, $opts) = @_;

    # check required params
    my @missing;
    foreach (qw(name1 street postal country)) {
        push(@missing, $_) unless $opts->{$_};
    }
    croak "required option ".join(',',map{"'$_'"}@missing)." missing" if @missing;

    # validata some params
    croak "'country' must be uppercase two letter ISO code (eg 'DE')" unless $opts->{country}=~/^[A-Z][A-Z]$/;

    my $self = bless $opts, $class;
    $self->_dpd($dpd);
    return $self;
}

sub _countryn {
    my ($self) = @_;
    return $self->_dpd->country_code($self->country)
}

sub as_mpsexpdata {
    my ($self, %opt) = @_;
    my @address_components = (
        qw(
            name1
            name2
            street
            houseno
            _countryn
        ),
        ($opt{state} ? 'state' : ()),
        qw(
            postal
            city
            contact
            phone
            fax
            email
            comment
            iln
        )
    );
    my @data = (
        map { $self->$_ // '' } @address_components);
    return (wantarray ? @data : join(';', @data));
}

sub as_array {
    my ($self) = @_;

    return (
        (map { $self->$_ // () } qw(name1 name2)),
        (join(' ', $self->street, ($self->houseno ? $self->houseno : ()))),
        uc($self->country).'-'.$self->postal.' '.$self->city,
        ($self->phone ? 'Tel.: '.$self->phone : ()),
    );
}

1;

__END__

=head1 NAME

Business::DPD::Address - DPD address object

=head1 SYNOPSIS

    use Business::DPD::Address;
    my $label = Business::DPD::Address->new($dpd, {
        name1   => 'DELICom DPD GmbH',
        street  => 'Wailandtstrasse 1',
        postal  => '63741',
        city    => 'Aschaffenburg',
        country => 'DE',
        phone   => '06021/ 0815',
        fax     => '06021/ 0816',
        email   => 'test.dpd@dpd.com',
        depot   => '0176',
    });

=head1 DESCRIPTION

Object representing DPD address fields.

=head1 METHODS

=head2 Public Methods

=head3 as_mpsexpdata

Return string or array of elements for DPD MPSEXPDATA file.

When called with C<state => 1> argument, also includes state in the
list. State is present in recipient, but not in originator address.

=head3 as_array

Returns address in a array of address lines suitable for rendering.

=head1 AUTHOR

Jozef Kutej E<lt>jkutej {at} cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
