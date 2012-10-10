use Test::More;
use Test::Deep;
use Ouch;

use lib '../lib';
use 5.010;

use_ok 'Box::Calc::Row';

my $row = Box::Calc::Row->new(max_x => 10);

isa_ok $row, 'Box::Calc::Row';
is $row->fill_x, 0, 'initially there are no dimensions for x';
is $row->fill_y, 0, '... y';
is $row->fill_z, 0, '... z';
is $row->max_x, 10, 'maximum x';

use Box::Calc::Item;
my $flat    = Box::Calc::Item->new(x => 1, y => 1, z => 1, name => 'Flat', weight => 1);
my $tall    = Box::Calc::Item->new(x => 5, y => 4, z => 2, name => 'Tall', weight => 5);
my $too_big = Box::Calc::Item->new(x => 14, y => 4, z => 2, name => 'Too big', weight => 5);

eval { $row->pack_item($too_big); };
ok kiss('x too big'), 'Caught X too big exception';

cmp_deeply $row->packing_list, [], 'nothing packed yet';

$row->pack_item($flat);

##Remember, sorted dimensions
is $row->fill_x, 1, 'layer inherits properties from the item, x';
is $row->fill_y, 1, '... y';
is $row->fill_z, 1, '... z';
is $row->calculate_weight, 1, '... weight'; 
cmp_deeply $row->packing_list, ['Flat'], 'packed one item';

$row->pack_item($flat);
is $row->fill_x, 2, 'incremented total x';
is $row->fill_y, 1, 'y does not increment';
is $row->fill_z, 1, 'z does not increment';
is $row->calculate_weight, 2, '... weight'; 
cmp_deeply $row->packing_list, [('Flat') x 2], 'packed two items';

$row->pack_item($tall);
is $row->fill_x, 7, 'incremented total x on tall';
is $row->fill_y, 4, 'y bumped';
is $row->fill_z, 2, 'z bumped';
is $row->calculate_weight, 7, '... weight'; 
cmp_deeply $row->packing_list, [('Flat') x 2, 'Tall'], 'packed three items';

eval { $row->pack_item($too_big); };
ok kiss('x too big'), 'Caught X too big exception';
is $row->fill_x, 7, 'internal dimensions not touched due to exception, x';
is $row->fill_y, 4, '... y';
is $row->fill_z, 2, '... z';
is $row->calculate_weight, 7, '... weight'; 

done_testing;
