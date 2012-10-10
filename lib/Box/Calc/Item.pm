package Box::Calc::Item;
BEGIN {
  $Box::Calc::Item::VERSION = '0.0100';
}

use strict;
use warnings;
use Moose;

with 'Box::Calc::Role::Dimensional';


=head1 NAME

Box::Calc::Item - The container class for the items you wish to pack.

=head1 VERSION

version 0.0100

=head1 SYNOPSIS

 my $item = Box::Calc::Item->new(name => 'Apple', x => 3, y => 3.3, z => 4, weight => 5);

=head1 METHODS

=head2 new(params)

Constructor.

=over

=item params

=over

=item x

The width of your item.

=item y

The length of your item.

=item z

The thickness of your item.

=item weight

The weight of your item.

=item name

The name of your item. If you're referring it back to an external system you may wish to use this field to store you item ids instead of item names.

=back

=back


=head2 name

Returns the name of this item.

=cut

has name => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
);

=head1 ROLES

This class installs L<Box::Calc::Role::Dimensional>.

=cut

no Moose;
__PACKAGE__->meta->make_immutable;