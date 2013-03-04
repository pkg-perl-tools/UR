package UR::Value::GLOB;

use strict;
use warnings;

require UR;
our $VERSION = "0.41_02"; # UR $VERSION;

UR::Object::Type->define(
    class_name => 'UR::Value::GLOB',
    is => ['UR::Value::PerlReference'],
);

1;
#$Header$
