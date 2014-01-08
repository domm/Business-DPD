package Business::DPD::DataExchange::mpsexpdata;

use strict;
use warnings;
use 5.010;

use version; our $VERSION = version->new('0.22');

use parent qw(Class::Accessor::Fast);
use Carp;
use POSIX 'ceil';
use List::Util 'sum';
use DateTime;

__PACKAGE__->mk_accessors(qw(
    consecutive_no
    delisid
    customer_id
    customer_subid
    labels

    packet_count

    pickup_time_from
    pickup_time_to
    pickup_mpsid
    pickup_originator_address
));

# internal
__PACKAGE__->mk_accessors(qw(now));

my $_new_line = "\r\n";

sub new {
    my ($class, $opts) = @_;

    # check required params
    my @missing;
    foreach (qw(delisid customer_id consecutive_no labels)) {
        push(@missing, $_) unless $opts->{$_};
    }
    croak "required option ".join(',',map{"'$_'"}@missing)." missing" if @missing;

    $opts->{now} //= DateTime->now('time_zone' => 'local');
    $opts->{packet_count} //= 0;

    # validata some params
    croak "'lables' must be an array" unless ref $opts->{labels} eq 'ARRAY';
    croak "'customer_id' must be 11 characters long" if length($opts->{customer_id}) != 11;
    # TODO validate if there is only one depo

    my $self = bless $opts, $class;
    return $self;
}

sub depot {
    my ($self) = @_;
    return $self->{depot} // $self->labels->[0]->depot;
}

sub filename {
    my ($self) = @_;
    my $dpd_now_string = $self->now->strftime('%Y%m%dT%H%M%S');
    return 'MPSEXPDATA_'.$self->delisid.'_CUST_'.$self->depot.'_D'.$dpd_now_string;
}

sub as_string {
    my ($self) = @_;

    return
        $self->file_header
        .$self->file_body
        .$self->file_footer;
}

sub file_header {
    my ($self) = @_;

    my $data = join(
        ';',
        '#FILE',
        $self->delisid,
        $self->depot,
        $self->now->strftime('%Y%m%d'),
        $self->now->strftime('%H%M%S'),
        $self->consecutive_no,
        $_new_line,
    );
    $data .= '#DEF;MPSEXP:HEADER;MPSID;MPSCOMP;MPSCOMPLBL;MPSCREF1;MPSCREF2;MPSCREF3;MPSCREF4;MPSCOUNT;MPSVOLUME;MPSWEIGHT;SDEPOT;SCUSTID;SCUSTSUBID;DELISUSR;SNAME1;SNAME2;SSTREET;SHOUSENO;SCOUNTRYN;SPOSTAL;SCITY;SCONTACT;SPHONE;SFAX;SEMAIL;SCOMMENT;SILN;CDATE;CTIME;CUSER;HARDWARE;RDEPOT;ESORT;RCUSTID;RNAME1;RNAME2;RSTREET;RHOUSENO;RCOUNTRYN;RSTATE;RPOSTAL;RCITY;RCONTACT;RPHONE;RFAX;REMAIL;RCOMMENT;RILN;MPSSERVICE;MPSSDATE;MPSSTIME;LATEPICKUP;UMVER;UMVERREF;PODMAN;;'.$_new_line;
    $data .= '#DEF;MPSEXP:PARCEL;MPSID;PARCELNO;CREF1;CREF2;CREF3;CREF4;DELISUSR;SERVICE;VOLUME;WEIGHT;HINSURE;HINSAMOUNT;HINSCURRENCY;HINSCONTENT;;'.$_new_line;
    if ($self->pickup_time_from && $self->pickup_time_to) {
        $data .= '#DEF;MPSEXP:PICKUP;MPSID;PTYPE;PNAME1;PNAME2;PSTREET;PHOUSENO;PCOUNTRYN;PPOSTAL;PCITY;PCONTACT;PPHONE;PFAX;PEMAIL;PILN;PDATE;PTOUR;PQUANTITY;PDAY;PFROMTIME1;PTOTIME1;PFROMTIME2;PTOTIME2;;'.$_new_line;
    }

    return $data;
}
sub file_footer {
    my ($self) = @_;

    my $data = '';
    if ($self->pickup_time_from && $self->pickup_time_to) {
        #PICKUP
        $data .= join(
            ';',
            'PICKUP',
            $self->pickup_mpsid, # MPSID
            '1', # PTYPE
            $self->pickup_originator_address->as_mpsexpdata(), # PNAME1, PNAME2, PSTREET, PHOUSENO, PCOUNTRYN, PPOSTAL, PCITY, PCONTACT, PPHONE, PFAX, PEMAIL, PILN
            $self->pickup_time_from->strftime('%Y%m%d'), # PDATE
            '', # PTOUR
            $self->packet_count, # PQUANTITY
            $self->pickup_time_from->strftime('%w'), # PDAY
            $self->pickup_time_from->strftime('%H%M'), # PFROMTIME1
            $self->pickup_time_to->strftime('%H%M'), # PTOTIME1
            '', # PFROMTIME2
            '', # PTOTIME2
            $_new_line,
        );
    }

    $data .= join(
        ';',
        '#END',
        $self->consecutive_no,
        $_new_line,
    );

    return $data;
}

sub file_body {
    my ($self) = @_;

    my $data = '';

    # group labels by recipient
    my %labels_per_recipient;
    foreach my $label (sort { $a->serial cmp $b->serial } @{$self->labels}) {
        my $recipient = $label->address->as_mpsexpdata(state => 1, comment => 1);
        $labels_per_recipient{$recipient} //= [];
        push(@{$labels_per_recipient{$recipient}}, $label);
    }
    #sort groups by serial
    my @sorted_recipient_labels = (
        sort {
            $a->[0]->serial
            cmp
            $b->[0]->serial
        } values %labels_per_recipient
    );

    foreach my $labels (@sorted_recipient_labels) {
        my $label_header = $labels->[0];
        $label_header->calc_fields unless $label_header->_fields_calculated;
        my $total_weight = sum map { $_->weight_g } @$labels;
        my $mpsid = 'MPS'.$label_header->tracking_number_without_checksum.$self->now->strftime('%Y%m%d');
        $self->pickup_mpsid($mpsid);
        $self->pickup_originator_address($label_header->_dpd->originator_address);

        #HEADER
        $data .= join(
            ';',
            'HEADER',
            $mpsid,
            '1', # MPSCOMP
            '0', # MPSCOMPLBL
            ($label_header->reference_number // ''), # MPSCREF1
            ($label_header->order_number     // ''), # MPSCREF2
            '', # MPSCREF3
            '', # MPSCREF4
            scalar(@$labels), #MPSCOUNT
            '', #MPSVOLUME
            ceil($total_weight/10), #MPSWEIGHT
            $label_header->depot, #SDEPOT
            $self->customer_id, # SCUSTID
            $self->customer_subid, #SCUSTSUBID
            $self->delisid, # DELISUSR
            $label_header->_dpd->originator_address->as_mpsexpdata(comment => 1), #SNAME1 - SILN
            '', #CDATE
            '', #CTIME
            '', #CUSER
            'K', #HARDWARE
            '', #RDEPOT
            '', #ESORT
            '', #RCUSTID
            $label_header->address->as_mpsexpdata(state => 1, comment => 1), #RNAME1 - RILN
            $label_header->service_code, #MPSSERVICE
            '', #MPSSDATE
            '', #MPSSTIME
            '0', #LATEPICKUP
            '0', #UMVER
            '', #UMVERREF
            '0', #PODMAN
            $_new_line,
        );

        foreach my $label (@$labels) {
            $label->calc_fields unless $label->_fields_calculated;

            #PARCEL
            $data .= join(
                ';',
                'PARCEL',
                $mpsid, # same as header for all packages
                $label->tracking_number_without_checksum,
                ($label->reference_number // ''), # CREF1
                ($label->order_number     // ''), # CREF2
                '', # CREF3
                '', # CREF4
                $self->delisid, # DELISUSR
                $label->service_code, #SERVICE
                '', #VOLUME
                ceil($label->weight_g/10), #WEIGHT
                '0', #HINSURE
                '0', #HINSAMOUNT
                '', #HINSCURRENCY
                '', #HINSCONTENT
                $_new_line,
            );

            $self->packet_count($self->packet_count+1);
        }
    }

    return $data;
}

sub _new_line { return "\r\n" }

sub parse_to_data {
    my ($self, $mpsexpdata) = @_;
    my @lines = split(/\v+/, $mpsexpdata);

    my %defs;
    my @mpsexpdata;
    while (my $line = shift @lines) {
        my @cols = split(/;/,$line);
        my $directive = shift(@cols);
        next if $directive eq '#FILE';
        next if $directive eq '#END';
        if ($directive eq '#DEF') {
            my $def_long_name = shift(@cols);
            die 'unknown #DEF '.$def_long_name
                unless $def_long_name =~ m/^MPSEXP:(.+)/;
            my $def_name = $1;
            $defs{$def_name} = \@cols;
            next;
        }
        elsif ($defs{$directive}) {
            my %attrs;
            foreach my $i (0..@{$defs{$directive}}-1) {
                $attrs{$defs{$directive}->[$i]} = $cols[$i] // '';
            };
            push(@mpsexpdata,{
                type => $directive,
                attrs => \%attrs,
            });
        }
        else {
            die 'unknown line '.$line;
        }
    }

    return @mpsexpdata;
}

1;

__END__

=head1 NAME

Business::DPD::DataExchange::mpsexpdata - generate MPSEXPDATA - batch file

=head1 SYNOPSIS

    use Business::DPD::DataExchange::mpsexpdata;

    my $mpsexpdata = Business::DPD::DataExchange::mpsexpdata->new({
        delisid        => 'DelisID',
        customer_id    => '67899999999',
        customer_subid => '005',
        consecutive_no => 4,
        labels         => [$dpd_label1, $dpd_label2],
    });
    say $mpsexpdata->filename;
    say $mpsexpdata->as_string;

    say Data::Dumper::Dumper([
        Business::DPD::DataExchange::mpsexpdata->parse_to_data()
    ]);

=head1 DESCRIPTION

Generates MPSEXPDATA file that can be send to DPD.

=head1 METHODS

=head2 Public Methods

=head3 new

constructor

=head3 filename

Returns DPD filename.
Ex.: C<MPSEXPDATA_DelisID_CUST_0176_D20061123T154215>

=head3 as_string

Returns content of MPSEXPDATA file that includes all labels composed
from C<file_header()> + C<file_body()> + C<file_footer()>

=head3 parse_to_data

Takes string with mpsexpdata file content and parses it to data structure.

=head1 AUTHOR

Jozef Kutej E<lt>jkutej {at} cpan.orgE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
