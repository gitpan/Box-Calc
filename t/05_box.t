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

isa_ok $box, 'Box::Calc::Box';

is $box->x, 12, 'x defaults to largest';
is $box->y, 12, 'y defaults to 12';
is $box->z, 12, 'z defaults to smallest';
is $box->fill_x, 0, 'fill_x 0';
is $box->fill_y, 0, 'fill_y 0';
is $box->fill_z, 0, 'fill_z 0';
is $box->name, 'test', 'overriding the default name';
is $box->calculate_weight, 20, 'taking box weight into account in weight calculations';

cmp_deeply $box->dimensions, [12,12,12], 'dimensions';

is $box->count_layers, 1, 'A new box has a layer created automatically';
cmp_deeply $box->packing_list, [[[]]], 'Empty packing list for an empty box';

can_ok($box, 'pack_item');

use Box::Calc::Item;
my $deck = Box::Calc::Item->new(x => 3.5, y => 2.5, z => 1, name => 'Deck', weight => 3);
my $tarot_deck = Box::Calc::Item->new(x => 4.75, y => 2.75, z => 1.25, name => 'Tarot Deck', weight => 4);
my $pawn = Box::Calc::Item->new(x => 1, y => 0.5, z => 0.5, name => 'Pawn', weight => 0.1);
my $die  = Box::Calc::Item->new(x => 0.75, y => 0.75, z => 0.75, name => 'Die', weight => 0.1);
my $mgbox = Box::Calc::Item->new(x => 8.75, y => 6.5, z => 1.25, name => 'Medium Game Box', weight => 6);
my $lgbox = Box::Calc::Item->new(x => 10.75, y => 10.75, z => 1.5, name => 'Large Game Box', weight => 12);

note 'Begin packing';
$box->pack_item($deck);
$box->pack_item($deck);
$box->pack_item($deck);
$box->pack_item($deck);
$box->pack_item($tarot_deck);
is $box->count_layers, 1, 'Still on one layer';
cmp_deeply $box->packing_list, [[[('Deck')x3], ['Deck', 'Tarot Deck'], ]], 'packing list before adding the large box';
$box->pack_item($lgbox); 

is $box->count_layers, 2, 'Added another layer';
is $box->fill_z, 2.75, 'fill_z for two layers';
cmp_deeply $box->packing_list, [
                                [ [('Deck')x3], ['Deck', 'Tarot Deck'], ],
                                [ ['Large Game Box'] ],
                               ], 'packing list, showing two layers';

foreach (1..6) {
    $box->pack_item($lgbox);
}
is $box->count_layers, 8, 'Added eight layers';
is $box->fill_z, 11.75, 'fill_z for 8 layers';
cmp_deeply $box->packing_list, [
                                [ [('Deck')x3], ['Deck', 'Tarot Deck'], ],
                                [ ['Large Game Box'] ],
                                [ ['Large Game Box'] ],
                                [ ['Large Game Box'] ],
                                [ ['Large Game Box'] ],
                                [ ['Large Game Box'] ],
                                [ ['Large Game Box'] ],
                                [ ['Large Game Box'] ],
                               ], 'packing list, showing multiple layers';
eval { $box->pack_item($lgbox); };
ok kiss('z too big'), 'Caught Z too big exception';

note tv_interval($t);

done_testing;

