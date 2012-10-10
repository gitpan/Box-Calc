package Box::Calc::Layer;
BEGIN {
  $Box::Calc::Layer::VERSION = '0.0100';
}

use strict;
use Moose;
use Box::Calc::Row;
use Ouch;

=head1 NAME

Box::Calc::Layer - A box is packed with multiple layers.

=head1 VERSION

version 0.0100

=head1 SYNOPSIS

 my $row = Box::Calc::Row->new(max_x => 6);
 
=head1 METHODS

=head2 new(params)

Constructor.

B<NOTE:> A layer is automatically created containing a single empty L<Box::Calc::Row>.

=over

=item max_x

The maximimum width of the layer. This is equivalent to the C<x> or longest dimension of the containing box. 

=item max_y

The maximimum depth of the layer. This is equivalent to the C<y> or middle dimension of the containing box. 

=back

=head2 fill_x()

Returns how full the layer is in the C<x> dimension.

=cut

sub fill_x {
    my $self = shift;
    my $value = 0;
    foreach my $row (@{$self->rows}) {
        $value = $row->fill_x if $row->fill_x > $value;
    }
    return $value;
}

=head2 fill_y()

Returns how full the layer is in the C<y> dimension.

=cut

sub fill_y {
    my $self = shift;
    my $value = 0;
    foreach my $row (@{$self->rows}) {
        $value += $row->fill_y;
    }
    return $value;
}

=head2 fill_z()

Returns how full the layer is in the C<z> dimension.

=cut

sub fill_z {
    my $self = shift;
    my $value = 0;
    foreach my $row (@{$self->rows}) {
        $value = $row->fill_z if $row->fill_z > $value;
    }
    return $value;
}

=head2 max_x()

Returns the maximum C<x> dimension of this layer. See C<new> for details.

=cut

has max_x => (
    is          => 'ro',
    required    => 1,
    isa         => 'Num',
);

=head2 max_y()

Returns the maximum C<y> dimension of this layer. See C<new> for details.

=cut

has max_y => (
    is          => 'ro',
    required    => 1,
    isa         => 'Num',
);

=head2 rows()

Returns an array reference of the list of L<Box::Calc::Row> contained in this layer.

=head2 count_rows()

Returns the number of rows contained in this layer.

=cut

has rows => (
    is => 'rw',
    isa => 'ArrayRef[Box::Calc::Row]',
    default   => sub { [] },
    traits  => ['Array'],
    handles => {
        count_rows => 'count',
    }
);

=head2 create_row()

Adds a new L<Box::Calc::Row> to this layer.

=cut

sub create_row {
    my $self = shift;
    push @{$self->rows}, Box::Calc::Row->new(max_x => $self->max_x);
}

sub BUILD {
    my $self = shift;
    $self->create_row;
}

=head2 calculate_weight()

Calculates and returns the weight of all the rows in this layer.

=cut

sub calculate_weight {
    my $self = shift;
    my $weight = 0;
    foreach my $row (@{$self->rows}) {
        $weight += $row->calculate_weight;
    }
    return $weight;
}

=head2 pack_item(item)

Add a L<Box::Calc::Item> to this layer.

=over

=item item

The L<Box::Calc::Item> instance you want to add to this layer.

=back

=cut

sub pack_item {
    my ($self, $item) = @_;
    eval { $self->rows->[-1]->pack_item($item) };
    if (kiss 'x too big') {
        my $remaining_y = $self->max_y - $self->fill_y;
        if ($item->y > $remaining_y) {
            ouch 'y too big', 'Item too big for this layer.'; 
        }
        else {
            $self->create_row;
            $self->pack_item($item);
        }
    }
}

=head2 packing_list()

Returns an array reference of L<Box::Calc::Row> packing lists.

=cut

sub packing_list {
    my $self = shift;
    my @rows = map { $_->packing_list } @{ $self->rows };
    return \@rows;
}



no Moose;
__PACKAGE__->meta->make_immutable;