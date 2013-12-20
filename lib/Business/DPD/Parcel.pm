package Business::DPD::Parcel;

use strict;
use warnings;
use 5.010;
use utf8;

use version; our $VERSION = version->new('0.22');

use parent qw(Class::Accessor::Fast);
use Carp;
use POSIX 'ceil';
use URI;
use LWP::UserAgent;
use Web::Scraper;
use HTML::Entities;
use DateTime::Format::Strptime;

# input data
__PACKAGE__->mk_accessors(qw(
    tracking_number
    ua
));

# internal
__PACKAGE__->mk_accessors(qw(
    _dpd_extranet_page
    _dpd_extranet_data
));

=head1 NAME

Business::DPD::Parcel - get status of a parcel

=head1 SYNOPSIS

    use Business::DPD::Parcel;
    my $dpd_parcel = Business::DPD::Parcel->new(
        tracking_number => '06505010803060',
    );
    say $dpd_parcel->dpd_extranet_link;
    say $dpd_parcel->pick_up_datetime;
    say $dpd_parcel->deliver_datetime;
    say $dpd_parcel->country;

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

sub new {
    my ($class, %opts) = @_;

    croak "need tracking_number" unless $opts{tracking_number};
    $opts{ua} ||= LWP::UserAgent->new(agent => __PACKAGE__ . "/" . $VERSION);

    my $self = bless \%opts, $class;
    return $self;
}

sub dpd_extranet_link {
    my ($self) = @_;
    return URI->new('http://extranet.dpd.de/cgi-bin/delistrack?typ=2lang=sk&pknr='.$self->tracking_number);
}

sub dpd_extranet_page {
    my ($self) = @_;

    return $self->_dpd_extranet_page
        if $self->_dpd_extranet_page;

    my $res = $self->ua->get($self->dpd_extranet_link);
    die 'failed to fetch '.$self->dpd_extranet_link.': '. $res->status_line
        unless $res->is_success;

    my $html = $res->decoded_content;
    $html =~ s/&nbsp;/ /g;
    $self->_dpd_extranet_page($html);
    return $html;
}

sub dpd_extranet_data {
    my ($self) = @_;

    return $self->_dpd_extranet_data
        if $self->_dpd_extranet_data;

    my %parcel;
    my $parcel_scraper = scraper {
        process '//table[@class="alternatingTable"]//tr', 'places[]' => scraper {
            process 'td', 'columns[]' => 'HTML';
        }
    };
    my $strp = DateTime::Format::Strptime->new(
        pattern   => '%m/%d/%Y %H:%M',
        time_zone => 'Europe/Vienna',
    );
    my @rows =
        # cells to hash
        map {
            my ($depot,$city,undef)   = split(/\s/,$_->[1]);
            my ($country,$zip,$route) = split(/\s?•\s?/,$_->[3]);
            my $scan_type = $_->[2];
            $scan_type =~ s/^\d+\s+//;
            $country =~ s/[()]//g;
            my $code = $_->[5];
            $code =~ s/,/ /g;
            my @codes = split(/\s+/, $code);
            +{
                date      => $strp->parse_datetime($_->[0]),
                depot     => $depot,
                city      => $city,
                country   => $country,
                zip       => $zip,
                route     => $route,
                scan_type => $scan_type,
                tour      => $_->[4],
                code      => \@codes,
            }
        }
        # clean-up cells
        map  { [map {
            $_ =~ s/<.+?>/ /g;
            $_ =~ s/\s+/ /g;
            $_ =~ s/^\s+//g;
            $_ =~ s/\s+$//g;
            decode_entities($_);
            $_.'';
        } @{$_}] }
        # only 6 cell rows
        grep { @{$_} == 6 }
        grep { ref($_) eq 'ARRAY' }
        map { $_->{columns} }
        @{$parcel_scraper->scrape($self->dpd_extranet_page, $self->dpd_extranet_link)->{places}};

    $parcel{places} = \@rows;

    $self->_dpd_extranet_data(\%parcel);
    return \%parcel;
}

sub pick_up_datetime {
    my ($self) = @_;
    
    my ($pickup) =
        map { $_->{date} }
        grep { $_->{scan_type} =~ m/Pick-up/i }
        @{$self->dpd_extranet_data->{places}};
    return $pickup;
}

sub deliver_datetime {
    my ($self) = @_;
    
    my ($delivered) =
        map { $_->{date} }
        grep { $_->{scan_type} =~ m/Delivered to/i }
        @{$self->dpd_extranet_data->{places}};
    return $delivered;
}


sub country { return $_[0]->_get_latest('country'); }
sub city    { return $_[0]->_get_latest('city'); }
sub zip     { return $_[0]->_get_latest('zip'); }

sub _get_latest {
    my ($self, $latest_name) = @_;
    my ($latest) =
        reverse
        grep { $_ }
        map { $_->{$latest_name} }
        @{$self->dpd_extranet_data->{places}};
    return $latest;
}

1;

__END__

=head1 AUTHOR

Jozef Kutej

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
