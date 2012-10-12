use Test::More;
use Test::Deep;
use Ouch;

use lib '../lib';
use 5.010;

use_ok 'Box::Calc';

my $calc = Box::Calc->new();

my $box_type = $calc->add_box_type({
    x => 2,
    y => 2,
    z => 2,
    weight => 6,
    name => '8 cube',
});

$calc->add_box_type({
    x => 3,
    y => 3,
    z => 3,
    weight => 9,
    name => '27 cube',
});

is $calc->count_box_types, 2, 'two box types';

$calc->add_item(7,
    x => 1,
    y => 1,
    z => 1,
    name => 'small die',
    weight => 1,
);

is $calc->count_items, 7, '7 items to pack';

$calc->pack_items();
is $calc->count_boxes, 1, 'only one box was used';
is $calc->get_box(-1)->name, '8 cube', 'smallest box was used';
cmp_deeply
    $calc->packing_list,
    [
      {
        name => '8 cube',
        weight => 13,
        packing_list => [
            [ [('small die')x2], [('small die')x2], ],
            [ [('small die')x2], [('small die')x1], ],
        ],
      },
    ],
    'top-level packing list, 7 items';

$calc->reset_boxes;

$calc->add_item(7,
    x => 1,
    y => 1,
    z => 1,
    name => 'small die',
    weight => 1,
);

$calc->pack_items();
is $calc->count_boxes, 1, 'only one box was used';
is $calc->get_box(-1)->name, '27 cube', 'largest box was used';
cmp_deeply
    $calc->packing_list,
    [
      {
        name => '27 cube',
        weight => 23,
        packing_list => [
            [ [('small die')x3], [('small die')x3], [('small die')x3], ],
            [ [('small die')x3], [('small die')x2], ],
        ],
      },
    ],
    'top-level packing list, 14 items';

$calc->reset_boxes;

$calc->add_item(14,
    x => 1,
    y => 1,
    z => 1,
    name => 'small die',
    weight => 1,
);
is $calc->count_items, 28, '28 items';
$calc->pack_items();
is $calc->count_boxes, 2, 'only one box was used';
@names = map { $_->name } @{ $calc->boxes };
cmp_deeply \@names, [('27 cube') x 2], 'used two boxes, both the largest';

cmp_deeply
    $calc->packing_list,
    [
      {
        name => '27 cube',
        weight => 36,
        packing_list => [  #3 items/row, 3 rows, 3 layers
            [ [('small die')x3], [('small die')x3], [('small die')x3], ],
            [ [('small die')x3], [('small die')x3], [('small die')x3], ],
            [ [('small die')x3], [('small die')x3], [('small die')x3], ],
        ],
      },
      {
        name => '27 cube',
        weight => 10,
        packing_list => [  #28th item should be in here
            [ [('small die')x1],  ],
        ],
      },
    ],
    'top-level packing list, 28 items';

done_testing;
