package UR::BoolExpr::Template::PropertyComparison::Between;

use strict;
use warnings;
use UR;
our $VERSION = "0.41_02"; # UR $VERSION;

UR::Object::Type->define(
    class_name  => __PACKAGE__, 
    is => ['UR::BoolExpr::Template::PropertyComparison'],
);

sub _compare {
    my ($self, $value, @property_value) = @_;
    my $lower_bound = $value->[0];
    my $upper_bound = $value->[1];

    my $cv_is_number = Scalar::Util::looks_like_number($lower_bound)
                       and
                       Scalar::Util::looks_like_number($upper_bound);

    no warnings 'uninitialized';
    foreach my $property_value ( @property_value ) {
        my $pv_is_number = Scalar::Util::looks_like_number($property_value);

        if ($cv_is_number and $pv_is_number) {
            return 1 if ( $property_value >= $lower_bound and $property_value <= $upper_bound);
        } else {
            return 1 if ( $property_value ge $lower_bound and $property_value le $upper_bound);
        }
    }
    return '';
}


1;

=pod

=head1 NAME

UR::BoolExpr::Template::PropertyComparison::Between - perform a 'between' test

=head1 DESCRIPTION

Evaluates to true of the property's value is between the lower and upper bounds, inclusive.
If the property returns multiple values, this comparison returns true if any of the values are
within the bounds.

=cut
