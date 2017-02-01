package Business::DPD::Parcel;

use strict;
use warnings;
use 5.010;
use utf8;

use version; our $VERSION = version->new('0.22');

use parent qw(Class::Accessor::Fast);
use Carp;
use URI;
use LWP::UserAgent;
use DateTime::Format::Strptime;
use JSON qw( decode_json );
use Data::Dumper qw(Dumper);

# input data
__PACKAGE__->mk_accessors(qw(
        tracking_number
        ua
        )
);

# internal
__PACKAGE__->mk_accessors(qw(
        _dpd_tracking_data_string
        _dpd_tracking_data
        _exists
        )
);

sub new {
    my ($class, %opts) = @_;

    croak "need tracking_number" unless $opts{tracking_number};
    $opts{ua} ||= LWP::UserAgent->new(agent => __PACKAGE__ . "/" . $VERSION);

    my $self = bless \%opts, $class;
    return $self;
}

sub dpd_tracking_link {
    my ($self) = @_;
    return URI->new(
        'https://tracking.dpd.de/cgi-bin/simpleTracking.cgi?locale=en_EN&type=1&parcelNr='
            . $self->tracking_number);
}

sub dpd_tracking_data_string {
    my ($self) = @_;
    return $self->_dpd_tracking_data_string if ($self->_dpd_tracking_data_string);

    my $res = $self->ua->get($self->dpd_tracking_link);
    die 'failed to fetch ' . $self->dpd_tracking_link . ': ' . $res->status_line
        unless ($res->is_success);

    my $json = $res->content;
    return $self->_dpd_tracking_data_string($json);
}

sub exists {
    my ($self) = @_;
    return $self->_exists if ($self->_exists);

    my $data = $self->dpd_tracking_data;

    my $exists = $data->{ErrorJSON} ? 0 : 1;
    return $self->_exists($exists);
}

sub dpd_tracking_data {
    my ($self) = @_;

    return $self->_dpd_tracking_data if ($self->_dpd_tracking_data);

    my $string = $self->dpd_tracking_data_string;

    #remove leading and trailing brackets ({ ... }) -> { ... }
    $string =~ s/^\(//;
    $string =~ s/\)$//;
    my $data = decode_json($string);

    warn "failed to fetch " . $self->dpd_tracking_link . ": " . $data->{ErrorJSON}->{message}
        if ($data->{ErrorJSON});

    $self->_dpd_tracking_data($data);
}

sub _hops {
    my ($self) = @_;

    return $self->dpd_tracking_data->{TrackingStatusJSON}->{statusInfos};
}

sub _hop_last {
    my ($self) = @_;
    return undef unless ($self->exists);
    return $self->_hops->[-1];
}

sub _hop_datetime {
    my ($self, $hop) = @_;

    my $strp = DateTime::Format::Strptime->new(
        pattern   => '%d/%m/%Y %H:%M',
        time_zone => 'Europe/Vienna',
    );
    return $strp->parse_datetime($hop->{date} . " " . $hop->{time}),;
}

sub _hop_country {
    my ($self, $hop) = @_;
    return undef unless ($hop);

    #~ "city":	"Unna (DE)",
    my ($city, $county) = split(/\s+/, $hop->{city});
    $county =~ s/[\(\)]//g;
    return $county;
}

sub _hop_city {
    my ($self, $hop) = @_;
    return undef unless ($hop);

    #~ "city":	"Unna (DE)",
    my ($city, $country) = split(/\s+/, $hop->{city});
    return $city;
}

sub pick_up_datetime {
    my ($self) = @_;
    return undef unless ($self->exists);

    foreach my $hop (@{$self->_hops}) {
        next unless ($hop->{contents}->[0]->{label} eq "Received by DPD from consignor.");
        return $self->_hop_datetime($hop);
    }

    die "pickup information not found ".Dumper($self->_hops);
}

sub delivered {
    my ($self) = @_;
    return undef unless ($self->exists);

    my $status = $self->dpd_tracking_data->{TrackingStatusJSON}->{shipmentInfo}->{deliveryStatus};
    return 1 if ($status == 5);
    return 0;
}

sub delivery_datetime {
    my ($self) = @_;

    return undef unless ($self->delivered);

    my $delivered = $self->_hops->[-1];
    return $self->_hop_datetime($delivered);
}

sub current_country {my $self = shift; return $self->_hop_country($self->_hop_last);}
sub current_city    {my $self = shift; return $self->_hop_city($self->_hop_last);}
sub zip {return die "method no longer available";}

1;

__END__

=head1 NAME

Business::DPD::Parcel - get status of a parcel

=head1 SYNOPSIS

    use Business::DPD::Parcel;
    my $dpd_parcel = Business::DPD::Parcel->new(
        tracking_number => '06505010803060',
    );
    say $dpd_parcel->dpd_tracking_link;

    say Dumper($dpd_parcel->dpd_tracking_data);

    die "parcel not found" unless ($dpd_parcel->exists);

    #these values will be undef if the parcel does not exist
    say $dpd_parcel->pick_up_datetime;
    say $dpd_parcel->delivery_datetime;
    say $dpd_parcel->current_country;
    say $dpd_parcel->current_city;

=head1 DESCRIPTION

Get the parcel data.

=head1 METHODS

=head2 Public Methods

=cut

=head3 new

    my $dpd_parcel = Business::DPD::Parcel->new(
        tracking_number => '06505010803060',
    );

=cut

=head1 AUTHOR

Jozef Kutej, C<< <jkutej at cpan.org> >>;
Andrea Pavlovic, C<< <spinne at cpan.org> >>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
