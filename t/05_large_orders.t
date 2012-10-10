use Test::More;
use Test::Deep;
use Ouch;

use lib '../lib';
use 5.010;
use Box::Calc::Box;
use strict;

use_ok 'Box::Calc::Box';

use Time::HiRes qw/gettimeofday tv_interval/;

my $t = [gettimeofday()];

my $box = Box::Calc::Box->new(x => 12, y => 12, z => 12, weight => 20, name => 'test');

use Box::Calc::Item;

note 'Begin packing';
foreach (1..1540) {
    my $car   = Box::Calc::Item->new(x => 2, y => 0.25, z => 0.125, name => 'Car', weight => 0.1);
    $box->pack_item($car);
}
foreach (1..662) {
    my $bills = Box::Calc::Item->new(x => 3, y => 2, z => 0.125, name => 'Bills', weight => 0.1);
    $box->pack_item($bills);
}
foreach (1..558) {
    my $die   = Box::Calc::Item->new(x => 0.5, y => 0.5, z => 0.5, name => 'Die', weight => 0.1);
    $box->pack_item($die);
}

note "Time to Execute: ".tv_interval($t);
note "Layer Count: ".$box->count_layers;
note "Fill X: ".$box->fill_x;
note "Fill Y: ".$box->fill_y;
note "Fill Z: ".$box->fill_z;
ok(1);

done_testing;

