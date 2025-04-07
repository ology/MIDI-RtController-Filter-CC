#!/usr/bin/env perl

# PERL_FUTURE_DEBUG=1 perl eg/control-change.pl

use curry;
use MIDI::RtController ();
use MIDI::RtController::Filter::CC ();

my $input_name  = shift || 'joystick';
my $output_name = shift || 'usb';

my $control = MIDI::RtController->new(
    input   => $input_name,
    output  => $output_name,
    verbose => 1,
);

my $filter1 = MIDI::RtController::Filter::CC->new(rtc => $control);
my $filter2 = MIDI::RtController::Filter::CC->new(rtc => $control);

$filter1->control(1);
# $filter1->range_bottom(10);
# $filter1->range_top(100);
# $filter1->range_step(2);
# $filter1->time_step(125_000);
# $filter1->step_up(10);
# $filter1->step_down(2);

$filter2->control(22);
# $filter2->range_bottom(10);
# $filter2->range_top(100);
# $filter2->range_step(2);
# $filter2->time_step(125_000);
# $filter2->step_up(10);
# $filter2->step_down(2);

$control->add_filter('stair_step', ['all'], $filter1->curry::stair_step);
$control->add_filter('breathe', ['all'], $filter2->curry::breathe);

$control->run;

# ...and now trigger a MIDI message!
