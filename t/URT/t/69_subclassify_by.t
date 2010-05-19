use warnings;
use strict;

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use UR;
use Test::More tests => 42;

UR::Object::Type->define(
    class_name => 'Acme',
    is => ['UR::Namespace'],
);

diag('Tests for subclassing by regular property');

our $calculate_called = 0;
UR::Object::Type->define(
    class_name => 'Acme::Employee',
    subclassify_by => 'subclass_name',
    is_abstract => 1,
    has => [
        name => { type => "String" },
        subclass_name => { type => 'String' },
    ],
);

UR::Object::Type->define(
    class_name => 'Acme::Employee::Worker',
    is => 'Acme::Employee',
);

UR::Object::Type->define(
    class_name => 'Acme::Employee::Boss',
    is => 'Acme::Employee',
);

my $e1 = eval { Acme::Employee->create(name => 'Bob') };
ok(! $e1, 'Unable to create an object from the abstract class without a subclass_name');
like($@, qr/abstract class requires param 'subclass_name' to be specified/, 'The exception was correct');

$e1 = Acme::Employee->create(name => 'Bob', subclass_name => 'Acme::Employee::Worker');
ok($e1, 'Created an object from the base class and specified subclass_name');
isa_ok($e1, 'Acme::Employee::Worker');
is($e1->name, 'Bob', 'Name is correct');
is($e1->subclass_name, 'Acme::Employee::Worker', 'subclass_name is correct');

$e1 = Acme::Employee::Worker->create(name => 'Bob2');
ok($e1, 'Created an object from a subclass without subclass_name');
isa_ok($e1, 'Acme::Employee::Worker');
is($e1->name, 'Bob2', 'Name is correct');
is($e1->subclass_name, 'Acme::Employee::Worker', 'subclass_name is correct');

$e1 = Acme::Employee->create(name => 'Fred', subclass_name => 'Acme::Employee::Boss');
ok($e1, 'Created an object from the base class and specified subclass_name');
isa_ok($e1, 'Acme::Employee::Boss');
is($e1->name, 'Fred', 'Name is correct');
is($e1->subclass_name, 'Acme::Employee::Boss', 'subclass_name is correct');

$e1 = Acme::Employee::Boss->create(name => 'Fred2');
ok($e1, 'Created an object from a subclass without subclass_name');
isa_ok($e1, 'Acme::Employee::Boss');
is($e1->name, 'Fred2', 'Name is correct');
is($e1->subclass_name, 'Acme::Employee::Boss', 'subclass_name is correct');

$e1 = Acme::Employee::Boss->create(name => 'Fred3', subclass_name => 'Acme::Employee::Boss');
ok($e1, 'Created an object from a subclass and specified the same subclass_name');
isa_ok($e1, 'Acme::Employee::Boss');
is($e1->name, 'Fred3', 'Name is correct');
is($e1->subclass_name, 'Acme::Employee::Boss', 'subclass_name is correct');



$e1 = eval { Acme::Employee::Worker->create(name => 'Joe', subclass_name => 'Acme::Employee') };
ok(! $e1, 'Creating an object from a subclass with the base class as subclass_name did not work');
like($@,
     qr/Value for subclassifying param 'subclass_name' \(Acme::Employee\) does not match the class it was called on \(Acme::Employee::Worker\)/,
     'Exception was correct');

$e1 = eval { Acme::Employee::Worker->create(name => 'Joe', subclass_name => 'Acme::Employee::Boss') };
ok(! $e1, 'Creating an object from a subclass with another subclass as subclass_name did not work');
like($@,
     qr/Value for subclassifying param 'subclass_name' \(Acme::Employee::Boss\) does not match the class it was called on \(Acme::Employee::Worker\)/,
     'Exception was correct');

$e1 = eval { Acme::Employee::Boss->create(name => 'Joe', subclass_name => 'Acme::Employee::Worker') };
ok(! $e1, 'Creating an object from a subclass with another subclass as subclass_name did not work');
like($@,
     qr/Value for subclassifying param 'subclass_name' \(Acme::Employee::Worker\) does not match the class it was called on \(Acme::Employee::Boss\)/,
     'Exception was correct');

$e1 = eval { Acme::Employee->create(name => 'Mike', subclass_name => 'Acme::Employee::NonExistent') };
ok(! $e1, 'Creating an object from the base class and gave invalid subclass_name did not work');
like($@,
     qr/Class Acme::Employee::NonExistent is not a subclass of Acme::Employee/,
     'Exception was correct');


diag('Tests for calculated subclassing');

$calculate_called = 0;
UR::Object::Type->define(
    class_name => 'Acme::Vehicle',
    is_abstract => 1,
    subclassify_by => 'subclass_name',
    has => [
        color => { is => 'String' },
        wheels => { is => 'Integer' },
        subclass_name => { calculate => sub { my $class = shift;
                                              my $params = shift;
                                              my $wheels = $params->{'wheels'};
                                              $calculate_called = 1;
                                              no warnings 'uninitialized';
                                              if ($wheels == 2) {
                                                  return 'Acme::Motorcycle';
                                              } elsif ($wheels == 4) {
                                                  return 'Acme::Car';
                                              } elsif (defined $wheels and $wheels == 0) {
                                                  return 'Acme::Sled';
                                              } else {
                                                 die "Can't create a vehicle with $wheels wheels";
                                              }
                                        },
                             },
    ],
);

UR::Object::Type->define(
    class_name => 'Acme::Motorcycle',
    is => 'Acme::Vehicle',
);

UR::Object::Type->define(
    class_name => 'Acme::Car',
    is => 'Acme::Vehicle',
);

UR::Object::Type->define(
    class_name => 'Acme::Sled',
    is => 'Acme::Vehicle',
);

$calculate_called = 0;
my $v = eval { Acme::Vehicle->create(color => 'blue') };
ok(! $v, 'Unable to create an object from the abstract class without a subclass_name');
like($@, qr/Can't create a vehicle with  wheels/, 'Exception was correct'); # note the extra space for undef
ok($calculate_called, 'The calculation function was called');

$calculate_called = 0;
$v = Acme::Vehicle->create(color => 'blue', wheels => 2, subclass_name => 'Acme::Motorcycle');
ok($v, 'Created an object from the base class by specifying subclass_name');
isa_ok($v, 'Acme::Motorcycle');
ok(! $calculate_called, 'The calculation function was not called');

$calculate_called = 0;
$v = Acme::Vehicle->create(color => 'green', wheels => 3, subclass_name => 'Acme::Motorcycle');
ok($v, 'Created another object from the base class');
isa_ok($v, 'Acme::Motorcycle');
ok(! $calculate_called, 'The calculation function was not called');

$calculate_called = 0;
$v = Acme::Vehicle->create(color => 'red', wheels => 4);
ok($v, 'Created an object from the base class by specifying wheels');
isa_ok($v, 'Acme::Car');
ok($calculate_called, 'The calculation function was called');

