package Business::DPD::DBIC;

use strict;
use warnings;
use 5.010;

use Carp;
use File::Spec::Functions qw(catfile);

=head1 NAME

Business::DPD::DBIC - DBIc::Class Interface to DPD data

=head1 SYNOPSIS

  use Business::DPD::DBIC;
  
  my $sqlite_file = Business::DPD::DBIC->path_to_sqlite

=head1 DESCRIPTION

A DBIx::Class based interface to various data sources needed to generate DPD labels.

=head1 METHODS

=head2 Public Methods

=cut

=head3 import_data

    Business::DPD::DBIC->path_to_sqlite({
        schema   => 'Business::DPD::DBIC::Schema',
        source   => '/path/to/data',
        connect  => [ DBI connect info ]
    });

Parses the plain text database provided by DPD and stores it into the 
database used by Business::DPD (which defaults to the build-in sqlite 
DB)

=cut

sub import_data {
    my ( $class, $opts ) = @_;

    croak "required parameter 'source' missing" unless $opts->{source};
    $opts->{schema} ||= 'Business::DPD::DBIC::Schema';
    #'Business::DPD::DBIC::Schema';
    unless ( $opts->{connect} ) {
        my $sqlite_file = $class->path_to_sqlite;
        $opts->{connect} = [ 'dbi:SQLite:dbname=' . $sqlite_file ];
    }

    eval "require $opts->{schema}";
    croak $@ if $@;

    my $schema = $opts->{schema}->connect( @{ $opts->{connect} } );

    $class->_import_country( $opts->{source}, $schema );
    $class->_import_routes( $opts->{source}, $schema );
    $class->_import_depot( $opts->{source}, $schema );

}

sub _import_file {
    my ( $class, $schema, $dir, $type, $callback ) = @_;

    my $dbfile = catfile( $dir, $type );
    open( my $fh, "<", $dbfile )
        || croak "Cannot read from $type = $dbfile: $!";
    foreach my $line (<$fh>) {
        chomp($line);
        next if $line =~ /^#/;
        next unless $line =~ /\w/;
        my @data = split( /\|/, $line );
        &$callback( $schema, \@data );
    }

}

sub _import_country {
    my ( $class, $dir, $schema ) = @_;

    croak "There is already data stored in table 'country'" if $schema->resultset('Country')->search->count;

    my @country;
    $class->_import_file(
        $schema, $dir,
        'COUNTRY',
        sub {
            my ( $schema, $data ) = @_;
            push(@country,{
                    num       => $data->[0],
                    alpha2    => $data->[1],
                    alpha3    => $data->[2],
                    languages => $data->[3],
                    flagpost  => $data->[4],
                }
            );
        }
    );
    
    $schema->resultset('Country')->populate( \@country );

}

sub _import_routes {
    my ( $class, $dir, $schema ) = @_;
    
   croak "There is already data stored in table 'routes'" if $schema->resultset('Route')->search->count;

    my @routes;
    $class->_import_file(
        $schema, $dir, 'ROUTES',
        sub {
            my ( $schema, $data ) = @_;

            # slicing for fun & profit!
            my %to_create;
            my @data = @$data;
            @to_create{
                qw(dest_country begin_postcode end_postcode service_code routing_places sending_date o_sort d_depot grouping_priority d_sort barcode_id)
                } = @data[ 0 .. 10 ];

            push(@routes,\%to_create);
        }
    );

    $schema->resultset('Route')->populate( \@routes );

}

sub _import_depot {
    my ( $class, $dir, $schema ) = @_;
    
   croak "There is already data stored in table 'depot'" if $schema->resultset('Depot')->search->count;

    my @routes;
    $class->_import_file(
        $schema, $dir, 'DEPOTS',
        sub {
            my ( $schema, $data ) = @_;

            # slicing for fun & profit!
            my %to_create;
            my @data = @$data;
            @to_create{
                qw( depot_number IATALikeCode group_id name1 name2 address1 address2 postcode city country phone fax mail web)
                } = @data[ 0 .. 10 ];

            push(@routes,\%to_create);
        }
    );

    $schema->resultset('Depot')->populate( \@routes );

}

=head3 path_to_sqlite

  my $sqlite_file = Business::DPD::DBIC->path_to_sqlite;

Returns the absolute path to the SQLite DB. You most likely won't need 
this...

=cut

sub path_to_sqlite {
    my $base = $INC{'Business/DPD/DBIC.pm'};
    $base =~ s/DBIC.pm$/dpd.sqlite/;
    return $base;
}

=head3 generate_sqlite

  Business::DPD::DBIC->generate_sqlite;

Generates a new sqlite DB and fills it with the data included in this 
dist.

Dies if a DB already exists.

=cut

sub generate_sqlite {
    my $class       = shift;
    my $sqlite_file = $class->path_to_sqlite;

    require DBI;

    croak "Database already exists: $sqlite_file." if -e $sqlite_file;
    my $dbh = DBI->connect( 'dbi:SQLite:dbname=' . $sqlite_file );

    $dbh->do( "
CREATE TABLE meta (
    version integer primary key,
    expires text,
    reference text
)
" );

    $dbh->do( "
CREATE TABLE country (
    num integer primary key,
    alpha2 text,
    alpha3 text,
    languages text,
    flagpost integer
)
" );

    $dbh->do( "
CREATE TABLE route (
    id integer PRIMARY KEY AUTOINCREMENT,
    dest_country text,
    begin_postcode text,
    end_postcode text,
    service_code text,
    routing_places text,
    sending_date text,
    o_sort text,
    d_depot text,
    grouping_priority text,
    d_sort text,
    barcode_id text
)
" );
    
    $dbh->do( "
CREATE TABLE depot (
    depot_number integer PRIMARY KEY,
    IATALikeCode text,
    group_id text,
    name1 text,
    name2 text,
    address1 text,
    address2 text,
    postcode text,
    city text,
    country text,
    phone text,
    fax text,
    mail text,
    web text
)
" );


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
