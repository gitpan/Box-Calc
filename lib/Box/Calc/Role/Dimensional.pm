package Box::Calc::Role::Dimensional;
BEGIN {
  $Box::Calc::Role::Dimensional::VERSION = '0.0200';
}

use strict;
use warnings;
use Moose::Role;

=head1 NAME

Box::Calc::Role::Dimensional - Role to add standard dimensions to objects.


=head1 VERSION

version 0.0200

=head2 SYNOPSIS

The x, y, and z attributes are first sorted from largest to smallest before creating the object. So you can insert them in any order. x=3, y=9, z=1 would become x=1, y=3, z=9.

   #----------#
   |          |
   |          |
   | Y        |
   |          |
   |          |
   |     X    |
   #----------#

 Z is from bottom up


=head1 METHODS

This role installs these methods:

=head2 x

Returns the largest side of an object.

=cut

has x => (
    is          => 'ro',
    required    => 1,
    isa         => 'Num',
);

=head2 y

Returns the middle side of an object.

=cut

has y => (
    is          => 'ro',
    required    => 1,
    isa         => 'Num',
);

=head2 z

Returns the shortest side of an object.

=cut

has z => (
    is          => 'ro',
    required    => 1,
    isa         => 'Num',
);

=head2 weight

Returns the weight of an object.

=cut

has weight => (
    is          => 'ro',
    isa         => 'Num',
    required    => 1,
);

=head2 volume

Returns the result of multiplying x, y, and z.

=cut

sub volume {
    my $self = shift;
    return $self->x * $self->y * $self->z;
}

=head2 dimensions

Returns an array reference containing x, y, and z.

=cut

sub dimensions {
    my $self = shift;
    return [$self->x, $self->y, $self->z];
}

around BUILDARGS => sub {
    my $orig      = shift;
    my $className = shift;
    my $args;
    if (ref $_[0] eq 'HASH') {
        $args = shift;
    }
    else {
        $args = { @_ };
    }

    # sort small to large
	my ( $x, $y, $z ) = sort { $b <=> $a } ( $args->{x}, $args->{y}, $args->{z} );
    
    $args->{x} = $x;
    $args->{y} = $y;
    $args->{z} = $z;
    return $className->$orig($args);
};

1;