package Box::Calc::Box;
BEGIN {
  $Box::Calc::Box::VERSION = '0.0101';
}

use strict;
use warnings;
use Moose;
use Storable qw(dclone);
with 'Box::Calc::Role::Dimensional';
use Box::Calc::Layer;
use Ouch;

=head1 NAME

Box::Calc::Box - The container in which we pack items.

=head1 VERSION

version 0.0101

=head1 SYNOPSIS

 my $box = Box::Calc::Box->new(name => 'Big Box', x => 12, y => 12, z => 18, weight => 20);

=head1 METHODS

=head2 new(params)

Constructor.

B<NOTE:> All boxes automatically have one empty L<Box::Calc::Layer> added to them.

=over

=item params

=over

=item name

An identifying name for your box.

=item x

The interior width of your box.

=item y

The interior length of your box.

=item z

The interior thickness of your box.

=item weight

The weight of your box.

=back

=back

=head2 fill_x()

Returns how full the box is in the C<x> dimension.

=cut

sub fill_x {
    my $self = shift;
    my $value = 0;
    foreach my $layer (@{$self->layers}) {
        $value = $layer->fill_x if $layer->fill_x > $value;
    }
    return $value;
}

=head2 fill_y()

Returns how full the box is in the C<y> dimension.

=cut

sub fill_y {
    my $self = shift;
    my $value = 0;
    foreach my $layer (@{$self->layers}) {
        $value = $layer->fill_y if $layer->fill_y > $value;
    }
    return $value;
}

=head2 fill_z()

Returns how full the box is in the C<z> dimension.

=cut

sub fill_z {
    my $self = shift;
    my $value = 0;
    foreach my $layer (@{$self->layers}) {
        $value += $layer->fill_z;
    }
    return $value;
}

=head2 name()

Returns the name of the box.

=cut

has name => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
);

=head2 layers()

Returns an array reference of the L<Box::Calc::Layer>s in this box.

=cut

has layers => (
    is => 'rw',
    isa => 'ArrayRef[Box::Calc::Layer]',
    default   => sub { [] },
    traits  => ['Array'],
    handles => {
        count_layers => 'count',
    }
);

=head2 calculate_weight()

Calculates and returns the weight of all the layers in this box, including the weight of this box.

=cut

sub calculate_weight {
    my $self = shift;
    my $weight = $self->weight;
    foreach my $layer (@{$self->layers}) {
        $weight += $layer->calculate_weight;
    }
    return $weight;
}

=head2 create_layer()

Adds a new L<Box::Calc::Layer> to this box.

=cut

sub create_layer {
    my $self = shift;
    push @{$self->layers}, Box::Calc::Layer->new( max_x => $self->x, max_y => $self->y, );
}

sub BUILD {
    my $self = shift;
    $self->create_layer;
}

=head2 pack_item(item)

Add a L<Box::Calc::Item> to this box.

=over

=item item

The L<Box::Calc::Item> instance you want to add to this box.

=back

=cut

sub pack_item {
    my ($self, $item) = @_;
    eval { $self->layers->[-1]->pack_item($item) };
    if (kiss 'y too big') {
        my $remaining_z = $self->z - $self->fill_z;
        if ($item->z > $remaining_z) {
            ouch 'z too big', 'Item too big for this box.'; 
        }
        else {
            $self->create_layer;
            $self->pack_item($item);
        }
    }
}

=head2 packing_list()

Returns an array reference of L<Box::Calc::Layer> packing lists.

=cut

sub packing_list {
    my $self = shift;
    my @layers = map { $_->packing_list } @{ $self->layers };
    return \@layers;
}


no Moose;
__PACKAGE__->meta->make_immutable;