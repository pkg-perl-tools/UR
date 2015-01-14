#!/usr/bin/env perl

use Test::More tests => 4;
use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use URT; 
use strict;
use warnings;

use Data::UUID;

subtest 'simple single-id class' => sub {
    plan tests => 12;

    my $tc1 = class TestClass1 {
        id_by => 'foo',
        has   => [
            foo   => { is => 'String' },
            value => { is => 'String' },
        ],
    };

    my $o = TestClass1->create(foo => 'aaaa', value => '1234');
    ok($o, "Created TestClass1 object with explicit ID");
    is($o->foo, 'aaaa', "Object's explicit ID has the correct value");
    is($o->foo, $o->id, "Object's implicit ID property is equal to the explicit property's value");

    $o = TestClass1->create(value => '2345');
    ok($o, "Created another TestClass1 object with an autogenerated ID");
    ok($o->foo, "The object has an autogenerated ID");
    is($o->foo, $o->id, "The object's implicit ID property is equal to the explicit property's value");

    my @id_parts = split(' ',$o->id);
    is($id_parts[0], Sys::Hostname::hostname(), 'hostname part of ID seen');
    is($id_parts[1], $$, 'process ID part of ID seen');
    # the 2nd part is the time and not reliably checked
    is($id_parts[3], $UR::Object::Type::autogenerate_id_iter, 'Iterator number part of ID seen');

    TestClass1->dump_error_messages(0);
    TestClass1->queue_error_messages(1);
    my $error_messages = TestClass1->error_messages_arrayref();

    $o = TestClass1->create(foo => 'aaaa', value => '123456');
    ok(!$o, "Correctly couldn't create an object with a duplicated ID");
    is(scalar(@$error_messages), 1, 'Correctly trapped 1 error message');
    like($error_messages->[0], qr/An object of class TestClass1 already exists with id value 'aaaa'/,
       'The error message was correct');
};


subtest 'dual-id class' => sub {
    plan tests => 19;

    my $tc2 = class TestClass2 {
        id_by => ['foo','bar'],
        has   => [
            foo   => { is => 'String' },
            bar   => { is => 'String' },
            value => { is => 'String' },
        ],
    };

    my $o = TestClass2->create(foo => 'aaaa', bar => 'bbbb', value => '1');
    ok($o, "Created a TestClass2 object with both explicit ID properties");
    is($o->foo, 'aaaa', "First explicit ID property has the right value");
    is($o->bar, 'bbbb', "Second explicit ID property has the right value");
    is($o->id, join("\t",'aaaa','bbbb'), "Implicit ID property has the right value");

    TestClass2->dump_error_messages(0);
    TestClass2->queue_error_messages(1);
    my $error_messages = TestClass2->error_messages_arrayref();

    my $composite_id = join("\t", 'c', 'd');
    $o = TestClass2->create(id => $composite_id);
    ok($o, 'Created a TestClass2 object using the composite ID');
    is($o->foo, 'c', 'First explicit ID property has the right value');
    is($o->bar, 'd', 'Second explicit ID property has the right value');
    is($o->id, $composite_id, 'Implicit ID property has the right value');

    $o = TestClass2->create(foo => 'qqqq', value => 'blah');
    ok(!$o, "Correctly couldn't create a multi-ID property object without specifying all the IDs");
    is(scalar(@$error_messages), 1, 'Correctly trapped 1 error messages');
    like($error_messages->[0], qr/Attempt to create TestClass2 with multiple ids without these properties: bar/,
       'The error message was correct');


    @$error_messages = ();
    $o = TestClass2->create(bar => 'wwww', value => 'blah');
    ok(!$o, "Correctly couldn't create a multi-ID property object without specifying all the IDs, again");
    is(scalar(@$error_messages), 1, 'Correctly trapped 1 error messages');
    like($error_messages->[0], qr/Attempt to create TestClass2 with multiple ids without these properties: foo/,
       'The error message was correct');


    @$error_messages = ();
    $o = TestClass2->create(value => 'asdf');
    ok(!$o, "Correctly couldn't create a multi-ID property object without specifying all the IDs, again");
    is(scalar(@$error_messages), 1, 'Correctly trapped 1 error messages');
    like($error_messages->[0], qr/Attempt to create TestClass2 with multiple ids without these properties: foo, bar/,
       'The error message was correct');


    @$error_messages = ();
    $o = TestClass2->create(foo => 'aaaa', bar => 'bbbb', value => '2');
    ok(!$o, "Correctly couldn't create another object with duplicated ID properites");
    like($error_messages->[0], qr/An object of class TestClass2 already exists with id value 'aaaa\tbbbb'/,
       'The error message was correct');
};


subtest 'parent and child classes' => sub {
    plan tests => 18;

    my $tc3 = class TestClass3 {
        id_by => 'foo',
        has => [
            foo   => { is => 'String' },
            value => { is => 'String' },
        ],
        id_generator => '-uuid',
    };

    my $tc_3_child = class TestClass3Child {
        is => 'TestClass3',
    };

    for my $class ( 'TestClass3','TestClass3Child' ) {
        is($class->__meta__->id_generator, '-uuid', "$class uses uuid for IDs");
        my $o = $class->create(foo => 'aaaa', value => '1234');
        ok($o, "Created TestClass3 object with explicit ID");
        is($o->foo, 'aaaa', "Object's explicit ID has the correct value");
        is($o->foo, $o->id, "Object's implicit ID property is equal to the explicit property's value");
        my $ug = eval { Data::UUID->new->from_hexstring('0x' . $o->foo) };
        ok(((! $ug) or ($ug eq pack('x16'))), 'It was not a properly formatted UUID');

        $o = TestClass3->create(value => '2345');
        ok($o, "Created another TestClass3 object with an autogenerated ID");
        ok($o->foo, "The object has an autogenerated ID");
        is($o->foo, $o->id, "The object's implicit ID property is equal to the explicit property's value");
        $ug = Data::UUID->new->from_hexstring($o->foo);
        ok($ug, 'It was a properly formatted UUID');
    }
};

subtest 'custom id generator' => sub {
    plan tests => 3;

    my $class_tc4_generator = 0;
    my $tc4 = class TestClass4 {
        id_by => 'foo',
        has => [
            foo   => { is => 'String' },
            value => { is => 'String' },
        ],
        id_generator => sub { ++$class_tc4_generator }, 
    };

    my $o = TestClass4->create(value => '12344');
    ok($o, 'Created TestClass4 object with an autogenerated ID');
    is($class_tc4_generator, 1, 'The generator anonymous sub was called');
    is($o->id, $class_tc4_generator, 'The object ID is as expected');
};

