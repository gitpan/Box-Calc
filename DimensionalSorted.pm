package Box::Calc::Role::DimensionalSorted;

use strict;
use warnings;
use Moose::Role;
with 'Box::Calc::Role::Dimensional';

around BUILDARGS => sub {
    my ($orig, $class, %args) = @_;

    # sort small to large
	my ( $x, $y, $z ) = sort { $b <=> $a } ( $args{x}, $args{y}, $args{z} );
    
    $args{x} = $x;
    $args{y} = $y;
    $args{z} = $z;
    return \%args;
};

1;
