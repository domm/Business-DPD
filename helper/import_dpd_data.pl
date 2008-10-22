#!/opt/perl5.10/bin/perl

use strict;
use warnings;
use 5.010;

use Business::DPD::DBIC;

my $sourcedir = $ARGV[0] || 'data';
die "sourcedir missing or does not exist!" unless -d $sourcedir;

Business::DPD::DBIC->import_data_into_sqlite({source=>$sourcedir});

__END__

=head1 NAME


