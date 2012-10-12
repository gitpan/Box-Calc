package Box::Calc;
BEGIN {
  $Box::Calc::VERSION = '0.0200';
}

use strict;
use Moose;
use Box::Calc::BoxType;
use Box::Calc::Item;
use Box::Calc::Box;
use Ouch;
use Log::Any qw($log);

=head1 NAME

Box::Calc - Packing Algorithm

=head1 VERSION

version 0.0200

=head1 SYNOPSIS

 use Box::Calc;
 
 my $box_calc = Box::Calc->new;
 
 # define the possible box types
 $box_calc->add_box_type( x => 12, y => 12, z => 18, weight => 16, name => 'big box' );
 $box_calc->add_box_type( x => 4, y => 6, z => 8, weight => 6, name => 'small box' );

 # define the items you want to put into boxes
 $box_calc->add_item( 3,  { x => 6, y => 3, z => 3, weight => 12, name => 'soda' });
 $box_calc->add_item( 1,  { x => 3.3, y => 3, z => 4, weight => 4.5, name => 'apple' });
 $box_calc->add_item( 2,  { x => 8, y => 2.5, z => 2.5, weight => 14, name => 'water bottle' });

 # figure out what you need to pack this stuff
 $box_calc->pack_items;
 
 # how many boxes do you need
 my $box_count = $box_calc->count_boxes; # 2
 
 # interogate the boes
 my $box = $box_calc->get_box(-1); # the last box
 my $weight = $box->calculate_weight;
 
 # get a packing list
 my $packing_list = $box_calc->packing_list;
  
=head1 DESCRIPTION

Box::Calc helps you determine what can fit into a box for shipping or storage purposes. It will try to use the smallest box possible of the box types. If every item won't fit into your largest box, then it will span the boxes letting you know how many boxes you'll need.

Once it's done packing the boxes, you can get a packing list for each box, as well as the weight of each box.

=head2 How The Algorithm Works

Box::Calc is intended to pack boxes in the simplest way possible. Here's what it does:

=over

=item 1

Sort all the items by volume.

=item 2

Eliminate all boxes that won't fit the largest items.

=item 3

Choose the smallest box still available.

=item 4

Place the items in a row starting with the largest items.

=item 5

When the row runs out of space, add another.

=item 6

When you run out of space to add rows, add a layer.

=item 7

When you run out of layers either start over with a bigger box, or if there are no bigger boxes span to a second box.

=item 8

Repeat from step 3 until all items are packed into boxes.

=back

=back

=head2 Motivation

At The Game Crafter (L<http://www.thegamecrafter.com>) we ship a lot of games and game pieces. We tried using a more complicated system for figuring out which size box to use, or how many boxes would be needed in a spanning situation. The problem was that those algorithms made the boxes pack so tightly that our staff spent a lot more time putting the boxes together. This algorithm is relatively dumb, but dumb in a good way. The boxes are easy and fast to pack. By releasing this, we hope it can help those who are either using too complicated a system, or no system at all for figuring out how many boxes they need for shipping/storing materials. 

=head2 Tips

When adding items, be sure to use the outer most dimensions of oddly shaped items, otherwise they may not fit the box.

When adding box types, be sure to use the inside dimensions of the box. If you plan to line the box with padding, then subtract the padding from the dimensions, and also add the padding to the weight of the box.

What units you use (inches, centimeters, ounces, pounds, grams, kilograms, etc) don't matter as long as you use them consistently. 

=head1 METHODS

=head2 new()

Constructor.

=head2 box_types()

Returns an array reference of the L<Box::Calc::BoxType>s registered.

=head2 count_box_types()

Returns the number of L<Box::Calc::BoxType>s registered.

=head2 get_box_type(index)

Returns a specific L<Box::Calc::BoxType> from the list of C<box_types>

=over

=item index

An array index. For example this would return the last box type added:

 $box_calc->get_box_type(-1)

=back

=cut

has box_types => (
    is => 'rw',
    isa => 'ArrayRef[Box::Calc::BoxType]',
    default   => sub { [] },
    traits  => ['Array'],
    handles => {
        push_box_types  => 'push',
        count_box_types => 'count',
        get_box_type    => 'get',
    }
);

=head2 add_box_type(params)

Adds a new L<Box::Calc::BoxType> to the list of C<box_types>. Returns the newly created L<Box::Calc::BoxType> instance.

=over

=item params

The list of constructor parameters for L<Box::Calc::BoxType>.

=back

=cut

sub add_box_type {
    my $self = shift;
    $self->push_box_types(Box::Calc::BoxType->new(@_));
    return $self->get_box_type(-1);
}

=head2 sort_box_types_by_volume()

Sorts the list of C<box_types> by volume and then returns an array reference of that list.

=cut

sub sort_box_types_by_volume {
    my $self = shift;
    my @sorted = sort { ($a->volume) <=> ($b->volume ) } @{$self->box_types};
    return \@sorted;
}

=head2 determine_viable_box_types()

Given the list of C<items> and the list of C<box_types> this method rules out box types that cannot hold the largest item, and returns the list of box types that will work sorted by volume. 

=cut

sub determine_viable_box_types {
    my $self = shift;
    my ($item_x, $item_y, $item_z) = sort {$a <=> $b} $self->find_max_dimensions_of_items;
    my @viable;
    foreach my $box_type (@{$self->sort_box_types_by_volume}) {
        my ($box_type_x, $box_type_y, $box_type_z) = @{$box_type->dimensions};
        if ($item_x <= $box_type_x && $item_y <= $box_type_y && $item_z <= $box_type_z) {
            push @viable, $box_type;
        }
    }
    unless (scalar @viable) {
        $log->fatal('There are no box types that can fit the items.');
        ouch 'no viable box types', 'There are no box types that can fit the items.', [$item_x, $item_y, $item_z];
    }
    return \@viable;
}

=head2 items()

Returns an array reference of the L<Box::Calc::Item>s registered.

=head2 count_items()

Returns the number of L<Box::Calc::Item>s registered.

=head2 get_item(index)

Returns a specific L<Box::Calc::Item>.

=over

=item index

The array index of the item as it was registered.

=back

=cut

has items => (
    is => 'rw',
    isa => 'ArrayRef[Box::Calc::Item]',
    default   => sub { [] },
    traits  => ['Array'],
    handles => {
        push_items  => 'push',
        count_items => 'count',
        get_item    => 'get',
    }
);

=head2 add_item(quantity, params)

Registers a new item. Returns the new item registered.

=over

=item quantity

How many copies of this item should be included in the package?

=item params

The constructor parameters for the L<Box::Calc::Item>.

=back

=cut

sub add_item {
    my ($self, $quantity, @params) = @_;
    my $item = Box::Calc::Item->new(@params);
    for (1..$quantity) {
        $self->push_items($item);
    }
    return $self->get_item(-1);
}

=head2 sort_items_by_volume()

Returns an array reference of the list of C<items> registered sorted by volume.

=cut

sub sort_items_by_volume {
    my $self = shift;
    my @sorted = sort { ($a->volume) <=> ($b->volume ) } @{$self->items};
    return \@sorted;
}

=head2 find_max_dimensions_of_items()

Given the registered C<items>, returns the max C<x>, C<y>, and C<z> of all items registered as a list.

=cut

sub find_max_dimensions_of_items {
    my $self = shift;
    my $x = 0;
    my $y = 0;
    my $z = 0;
    foreach my $item (@{$self->items}) {
        my ($ex, $ey, $ez) = @{$item->dimensions};
        $x = $ex if $ex > $x;
        $y = $ey if $ey > $y;
        $z = $ez if $ez > $z;
    }
    return ($x, $y, $z);
}

=head2 boxes()

Returns an array reference of the list of L<Box::Calc::Box>es needed to pack up the items.

B<NOTE:> This will be empty until you call C<pack_items>.

=head2 count_boxes()

Returns the number of boxes needed to pack up the items.

=head2 get_box(index)

Fetches a specific box from the list of <boxes>.

=over

=item index

The array index of the box you wish to fetc.

=back

=cut

has boxes => (
    is => 'rw',
    isa => 'ArrayRef[Box::Calc::Box]',
    default   => sub { [] },
    traits  => ['Array'],
    handles => {
        push_boxes  => 'push',
        count_boxes => 'count',
        get_box    => 'get',
    }
);

=head2 reset_boxes()

Deletes the list of C<boxes>.

If you wish to rerun the packing you should use this to delete the list of C<boxes> first. This is handy if you needed to add an extra item or extra box type after you already ran C<pack_items>.

=cut

sub reset_boxes {
    my $self = shift;
    $self->boxes([]);
}

=head2 reset_items()

Deletes the list of C<items>.

For the sake of speed you may wish to reuse a L<Box::Calc> instance with the box types already pre-loaded. In that case you'll want to use this method to remove the items you've already registered. You'll probably also want to call C<reset_boxes>.

=cut

sub reset_items {
    my $self = shift;
    $self->items([]);
}

=head2 pack_items()

Uses the list of C<box_types> and the list of C<items> to create the list of boxes to be packed. This method populates the C<boxes> list.

=cut

sub pack_items {
    my $self = shift;
    my @box_types = @{$self->determine_viable_box_types};
    my $countdown = scalar(@box_types);
    BOXTYPE: foreach my $box_type (@box_types) {
        $log->info("Box Type: ".$box_type->name);
        $countdown--;
        my $box = Box::Calc::Box->new(x => $box_type->x, y => $box_type->y, z => $box_type->z, weight => $box_type->weight, name => $box_type->name);
        ITEM: foreach my $item (@{$self->sort_items_by_volume}) {
            $log->info("Item: ".$item->name);
            eval { $box->pack_item($item)};
            if (hug) {
                if ($countdown) { # we still have other boxes to try
                    $log->info("moving to next box type because: $@");
                    next BOXTYPE;
                }
                else { # no more boxes to try, time for spanning
                    $log->info("no more box types, spanning because: $@");
                    $self->push_boxes($box);
                    $box = Box::Calc::Box->new(x => $box_type->x, y => $box_type->y, z => $box_type->z, weight => $box_type->weight, name => $box_type->name);
                    redo ITEM;
                }
            }
        }
        
        # we made it through our entire item list, yay!
        $log->info("finished!");
        $self->push_boxes($box);
        last BOXTYPE;
    }
}

=head2 packing_list()

Returns a data structure with all the item names packed into boxes. This can be used to build documentation on how to pack a set of boxes.

 [
    {                                   # box one
        name            => "big box",
        weight          => 94.5,
        packing_list    => [            # layer one
            [                           # row one
                "soda",
                "soda",
                "soda",
                "apple",
            ],
            [                           # row two
                "water bottle",
                "water bottle",
            ],
        ]
    }
 ]

=cut

sub packing_list {
    my $self = shift;
    my @boxes;
    foreach my $box (@{$self->boxes}) {
        push @boxes, {
            name            => $box->name,
            weight          => $box->calculate_weight,
            packing_list    => $box->packing_list,
        };
    }
    return \@boxes;
}

=head1 TODO

There are some additional optimizations that could be done to speed things up a bit. We might also be able to get a better fill percentage (less void space), although that's not really the intent of Box::Calc.

=head1 PREREQS

L<Moose>
L<Ouch>
L<Log::Any>

=head1 SUPPORT

=over

=item Repository

L<http://github.com/rizen/Box-Calc>

=item Bug Reports

L<http://github.com/rizen/Box-Calc/issues>

=back


=head1 SEE ALSO

Although these modules don't solve the same problem as this module, they may help you build something that does if Box::Calc doesn't quite help you do what you want.

=over

=item L<Algorithm::Knapsack>

=item L<Algorithm::Bucketizer>

=item L<Algorithm::Knap01DP>

=back

=head1 AUTHOR

=over

=item JT Smith <jt_at_plainblack_dot_com>

=item Colin Kuskie <colink_at_plainblack_dot_com>

=back

=head1 LEGAL

Box::Calc is Copyright 2012 Plain Black Corporation (L<http://www.plainblack.com>) and is licensed under the same terms as Perl itself.

=cut

no Moose;
__PACKAGE__->meta->make_immutable;