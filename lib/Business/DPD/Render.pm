package Business::DPD::Render;

use strict;
use warnings;
use 5.010;

use parent qw(Class::Accessor::Fast);
use Carp;

__PACKAGE__->mk_accessors(qw(_dpd outdir originator));


=head1 NAME

Business::DPD::Render - render a lable

=head1 SYNOPSIS

    use Business::DPD::Render::SomeSubclass;
    my $renderer = Business::DPD::Render::SomeSubclass->new( $dpd, {
        outdir => '/path/to/output/dir/',    
        originator => ['some','lines','of text'],
    });
    my $path = $renderer->render( $label );

=head1 DESCRIPTION

You should really use a subclass of this module!

=head1 METHODS

=head2 Public Methods

=cut

=head3 new
    
    my $renderer = Business::DPD::Render::SomeSubclass->new( $dpd, {
        outdir => '/path/to/output/dir/',    
        originator => ['some','lines','of text'],
    });

=cut

sub new {
    my ($class, $dpd, $opts) = @_;

    my $self = bless $opts, $class;
    $self->_dpd($dpd);
    return $self;
}

=head3 render

Render a label - HAS TO BE IMPLEMENTED IN SUBCLASS!

=cut

sub render {
    croak "'render' has to be implemented in a subclass";
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
