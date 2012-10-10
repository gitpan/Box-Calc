package Box::Calc::Row;
BEGIN {
  $Box::Calc::Row::VERSION = '0.0101';
}

use strict;
use Moose;
use Box::Calc::Item;
use Ouch;

=head1 NAME

Box::Calc::Row - The smallest organizational unit in a box.

=head1 VERSION

version 0.0101

=head1 SYNOPSIS

 my $row = Box::Calc::Row->new(max_x => 6);
 
=head1 METHODS

=head2 new(params)

Constructor.

=over

=item max_x

The maximimum width of the row. This is equivalent to the C<x> or longest dimension of the containing box. 

=back

=head2 fill_x()

Returns how full the row is in the C<x> dimension.

=cut

has fill_x => (
    is          => 'rw',
    default     => 0,
    isa         => 'Num',
);

=head2 fill_y()

Returns how full the row is in the C<y> dimension.

=cut

has fill_y => (
    is          => 'rw',
    default     => 0,
    isa         => 'Num',
);

=head2 fill_z()

Returns how full the row is in the C<z> dimension.

=cut

has fill_z => (
    is          => 'rw',
    default     => 0,
    isa         => 'Num',
);

=head2 max_x()

Returns the maximum C<x> dimension of this row. See C<new> for details.

=cut

has max_x => (
    is          => 'ro',
    required    => 1,
    isa         => 'Num',
);

=head2 items()

Returns an array reference of items contained in this row.

=head2 count_items()

Returns the number of items contained in this row.

=cut

has items => (
    is => 'rw',
    isa => 'ArrayRef[Box::Calc::Item]',
    default   => sub { [] },
    traits  => ['Array'],
    handles => {
        count_items => 'count',
    }
);

=head2 calculate_weight()

Calculates the weight of all the items in this row, and returns that value.

=cut

sub calculate_weight {
    my $self = shift;
    my $weight = 0;
    foreach my $item (@{$self->items}) {
        $weight += $item->weight;
    }
    return $weight;
}

=head2 pack_item(item)

Places an item into the row, and updates all the relevant statistics about the row.

Throws C<x too big> L<Ouch> if the item cannot fit into the row.

=over

=item item

A L<Box::Calc::Item> instance.

=back

=cut

sub pack_item {
    my ($self, $item) = @_;
    my $remaining_x = $self->max_x - $self->fill_x;
    if ($item->x > $remaining_x) {
        ouch 'x too big', 'Item too big for this row.'; 
    }
    push @{$self->items}, $item;
    $self->fill_x($self->fill_x + $item->x);
    $self->fill_y($item->y) if $item->y > $self->fill_y;
    $self->fill_z($item->z) if $item->z > $self->fill_z;
}

=head2 packing_list()

Returns an array reference of item names contained in this row.

=cut

sub packing_list {
    my $self = shift;
    my @items = map { $_->name } @{ $self->items };
    return \@items;
}

no Moose;
__PACKAGE__->meta->make_immutable;