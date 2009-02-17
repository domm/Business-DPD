package Business::DPD;

use strict;
use warnings;
use 5.010;

use version; our $VERSION = version->new('0.20');

use parent qw(Class::Accessor::Fast);
use Business::DPD::DBIC;
use Business::DPD::Label;
use Carp;

__PACKAGE__->mk_accessors(qw(schema schema_class dbi_connect _iso7064_mod37_36_checksum_map));

=head1 NAME

Business::DPD - handle DPD label generation

=head1 SYNOPSIS

    use Business::DPD;
    my $dpd = Business::DPD->new;
    $dpd->connect_schema; 
    my $label = $dpd->generate_label({
        zip             => '12555',
        country         => 'DE',
        depot           => '1090',
        serial          => '5012345678',
        service_code    => '101',    
    });
    say $label->tracking_number;
    say $label->d_sort;


=head1 DESCRIPTION

Calculate routing information for parcel sending via DPD (http://dpd.com)

Generate labels for parcels (including barcode)

=head1 METHODS

=head2 Public Methods

=cut

=head3 new

    my $dpd = Business::DPD->new();

Perl default, Business::DPD will use the included SQLite DB and 
C<Business::DPD::DBIC::Schema>. If you want to use another DB or 
another schema-class, you can define them via the options 
C<schema_class> and C<dbi_connect>.

    my $dpd = Business::DPD->new({
        schema_class => 'Your::Schema::DPD',
        dbi_connect  => ['dbi:Pg:dbname=yourdb','dbuser','dbpasswd', { } ],
    });

=cut

sub new {
    my ($class, $opts) = @_;

    $opts->{schema_class} ||= 'Business::DPD::DBIC::Schema';
    $opts->{dbi_connect} ||= [ 'dbi:SQLite:dbname=' . Business::DPD::DBIC->path_to_sqlite ];

    my $self = bless $opts, $class;
    return $self;
}

=head3 connect_schema

    $dpd->connect_schema;

Connect to the Schema/DB specified in L<new>.

Stores the DBIx::Class Schema in C<< $dpd->schema >>. 

=cut

sub connect_schema {
    my $self = shift;

    eval "require ".$self->schema_class;
    croak $@ if $@;

    my $schema = $self->schema_class->connect(@{$self->dbi_connect});
    $self->schema($schema);

}

=head3 generate_label

    my $label = $dpd->generate_label({
        zip             => '12555',
        country         => 'DE',
        depot           => '1090',
        serial          => '5012345678',
        service_code    => '101',    
    });

=cut

sub generate_label {
    my ($self, $data) = @_;

    my $label = Business::DPD::Label->new($self, $data);
}

sub iso7064_mod37_36_checksum {
    my $self = shift;
    my $string = shift;
    my ($map, $chars) = $self->iso7064_mod37_36_checksum_map;
    
    my $m  = 36;
    my $m1 = $m + 1;
    my $p  = $m;

    foreach my $chr ( split( //, uc($string) ) ) {
        if ( defined $map->{$chr} ) {
            $p += $map->{$chr};
            $p -= $m if ( $p > $m );
            $p *= 2;
            $p -= $m1 if ( $p >= $m1 );
        }
        else {
            croak "Cannot find value for $chr";
        }
    }
    $p = $m1 - $p;
    return ( $p == $m ) ? $chars->[0] : $chars->[$p];
}

sub iso7064_mod37_36_checksum_map {
    my $self = shift;
    my @chars = ( 0 .. 9, 'A' .. 'Z', '*' );
    my $map = $self->_iso7064_mod37_36_checksum_map;
    return ($map,\@chars) if $map;

    my $count = 0;
    my %map   = ();
    for (@chars) {
        $map{$_} = $count;
        $count++;
    }
    $self->_iso7064_mod37_36_checksum_map(\%map);
    return (\%map,\@chars);
}

1;

__END__

=head1 AUTHOR

Thomas Klausner C<< domm AT cpan.org >>

RevDev E<lt>we {at} revdev.atE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
