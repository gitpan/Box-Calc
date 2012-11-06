package Box::Calc;
BEGIN {
  $Box::Calc::VERSION = '0.0501';
}

use strict;
use Moose;
use Box::Calc::BoxType;
use Box::Calc::Item;
use Ouch;
use JSON qw(to_json from_json);
use AnyEvent::HTTP::LWP::UserAgent;
use AnyEvent;

=head1 NAME

Box::Calc - Packing Algorithm

=head1 VERSION

version 0.0501

=head1 SYNOPSIS

 use Box::Calc;
 
 my $box_calc = Box::Calc->new(api_key => 'xxx');
 
 # define the possible box types
 $box_calc->add_box_type( x => 12, y => 12, z => 18, weight => 16, name => 'big box' );
 $box_calc->add_box_type( x => 4, y => 6, z => 8, weight => 6, name => 'small box' );

 # define the items you want to put into boxes
 $box_calc->add_item( 3,  { x => 6, y => 3, z => 3, weight => 12, name => 'soda' });
 $box_calc->add_item( 1,  { x => 3.3, y => 3, z => 4, weight => 4.5, name => 'apple' });
 $box_calc->add_item( 2,  { x => 8, y => 2.5, z => 2.5, weight => 14, name => 'water bottle' });

 # get a packing list synchronously
 my $packing_list = $box_calc->packing_list->recv;

 # get a packing list asynchronously 
 my $cv = $box_calc->packing_list;
 # ... do stuff ...
 my $packing_list = $cv->recv;

  
=head1 DESCRIPTION

Box::Calc helps you determine what can fit into a box for shipping or storage purposes. It will try to use the smallest box possible of the box types. If every item won't fit into your largest box, then it will span the boxes letting you know how many boxes you'll need.

Once it's done packing the boxes, you can get a packing list for each box, as well as the weight of each box.

=head2 Tips

When adding items, be sure to use the outer most dimensions of oddly shaped items, otherwise they may not fit the box.

When adding box types, be sure to use the inside dimensions of the box. If you plan to line the box with padding, then subtract the padding from the dimensions, and also add the padding to the weight of the box.

What units you use (inches, centimeters, ounces, pounds, grams, kilograms, etc) don't matter as long as you use them consistently. 

=head1 METHODS

=head2 new(api_key)

Constructor.

=over

=item api_key

An API Key from L<http://www.boxcalc.net>.

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

has api_key => (
    is          => 'ro',
    required    => 1,
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

has implementation => (
    is  => 'rw',
    default => 'perl',
);

=head2 add_item(quantity, params)

Registers a new item. Returns the new item registered.

=over

=item params

The constructor parameters for the L<Box::Calc::Item>.

=back

=cut

sub add_item {
    my ($self, @params) = @_;
    my $item = Box::Calc::Item->new(@params);
    $self->push_items($item);
    return $self->get_item(-1);
}

=head2 packing_list()

Returns a data structure with all the item names and quantities packed into boxes. This can be used to generate manifests.

 [
    {                                   # box one
        id              => "xxx",
        name            => "big box",
        weight          => 30.1,
        packing_list    => {
            "soda"          => 3,
            "apple"         => 1,
            "water bottle"  => 2,
        }
    }
 ]

=cut

sub packing_list {
    my $self = shift;
    my $payload = {api_key => $self->api_key, implementation => $self->implementation};
    foreach my $type (@{$self->box_types}) {
        push @{$payload->{box_types}}, {
            weight      => $type->weight,
            x           => $type->x,
            y           => $type->y,
            z           => $type->z,
            name        => $type->name,
        };
    }
    foreach my $item (@{$self->items}) {
        push @{$payload->{items}}, {
            quantity    => $item->quantity,
            item        => {
                weight      => $item->weight,
                x           => $item->x,
                y           => $item->y,
                z           => $item->z,
                name        => $item->name,
            },
        };
    }
    return $self->_call('packing_list', [$payload]);
}

=head2 shipping_options( params )

Returns a data structure with all the item names and quantities packed into boxes, and all the shipping methods and prices. This can be used to provide shipping pricing options.

 {
     'USPS Parcel Post' => {
         postage            => 11.12,
         number_of_parcels  => 1,
         weight             => 30.1,
         parcels            => [
            {                                   # box one
                id              => "xxx",
                name            => "big box",
                weight          => 30.1,
                packing_list    => {
                    "soda"          => 3,
                    "apple"         => 1,
                    "water bottle"  => 2,
                },
                shipping        => {
                    postage     => 11.12,
                }
            }
        ]
    }
 }

=over

=item params

A hash of parameters that affect the results returned.

=over

=item from

A 5 digit zip code where the packages will originate from.

=item to

A 5 digit zip code (if shipping inside the United States)  or the name of a country (if shipping outside the United States).

=back

=back

=cut

sub shipping_options {
    my ($self, %params) = @_;
    ouch('bad param', '"from" must be a 5 digit zip code.', 'from') unless $params{from} =~ m/^\d{5}$/xms;
    ouch('bad param', '"to" must be a 5 digit zip code or a country name.', 'to') unless ($params{to} =~ m/^\d{5}$/xms || length($params{to}) > 5);
    my $payload = {api_key => $self->api_key, implementation => $self->implementation, to => $params{to}, from => $params{from}};
    foreach my $type (@{$self->box_types}) {
        push @{$payload->{box_types}}, {
            weight      => $type->weight,
            x           => $type->x,
            y           => $type->y,
            z           => $type->z,
            name        => $type->name,
            compatible_services  => $type->compatible_services,
        };
    }
    foreach my $item (@{$self->items}) {
        push @{$payload->{items}}, {
            quantity    => $item->quantity,
            item        => {
                weight      => $item->weight,
                x           => $item->x,
                y           => $item->y,
                z           => $item->z,
                name        => $item->name,
            },
        };
    }
    return $self->_call('shipping_options', [$payload]);
}

has _uri => (
    is          => 'rw',
    default     => 'https://api.boxcalc.net/rpc',
);

sub _call {
    my ($self, $method, $params) = @_;
    my $payload = { 
        jsonrpc     => '2.0',
        id          => 1,
        method      => $method,
        params      => $params,
    };  
    my $ua = AnyEvent::HTTP::LWP::UserAgent->new;
    $ua->timeout(30);
    my $cv = AnyEvent->condvar;
    $ua->post_async($self->_uri, 
        Content_Type    => 'application/json', 
        Content         => to_json($payload), 
        Accept          => 'application/json')->cb(sub {
            my $response = shift->recv;
            my $content = $response->decoded_content;
            my $hash = eval{from_json($content)};
            if ($@) {
                ouch 500, 'Unable to parse response.', $content;
            }
            if (exists $hash->{error}) {
                ouch $hash->{error}{code}, $hash->{error}{message}, $hash->{error}{data};
            }
            $cv->send($hash->{result});
        });
    return $cv;
}

=head1 PREREQS

L<Moose>
L<Ouch>
L<AnyEvent>
L<AnyEvent::HTTP::LWP::UserAgent>
L<JSON>

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