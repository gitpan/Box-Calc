use Test::More;
use Test::Deep;

use lib '../lib';
use 5.010;

use_ok 'Box::Calc';

note "API Key: $ENV{BOX_CALC_API_KEY}";
my $calc = Box::Calc->new(api_key => $ENV{BOX_CALC_API_KEY});

isa_ok $calc, 'Box::Calc';

$calc->add_box_type(
            name        => 'A',
            weight      => 20,
            x           => 5,
            y           => 10,
            z           => 8,
        );
$calc->add_box_type(
            name        => 'B',
            weight      => 7,
            x           => 4,
            y           => 6,
            z           => 2,
        );
$calc->add_item(
            quantity    => 5,
            name        => 'Banana',
            weight      => 5,
            x           => 3,
            y           => 1,
            z           => 4.5,
        );

my $packing_list = $calc->packing_list->recv;
is ref $packing_list, 'ARRAY', 'got a list back';
is $packing_list->[0]{name}, 'A', 'box A as it should be';

$calc->add_item(
            quantity    => 1,
            name        => 'T-Square',
            weight      => 16,
            x           => 12,
            y           => 24,
            z           => 0.25,
        );

my $cv = $calc->packing_list;

isa_ok $cv, 'AnyEvent::CondVar';

eval { $cv->recv };

isa_ok $@, 'Ouch';


done_testing;
