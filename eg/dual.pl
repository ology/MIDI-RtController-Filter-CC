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
my $filter3 = MIDI::RtController::Filter::CC->new(rtc => $control);

$filter1->control(1); # mod-wheel
# $filter1->range_bottom(10);
# $filter1->range_top(100);
# $filter1->range_step(2);
# $filter1->time_step(0.4);
# $filter1->step_up(10);
# $filter1->step_down(2);

$filter2->control(22); # noise
$filter2->range_bottom(0);
$filter2->range_top(80);
# $filter2->range_step(2);
# $filter2->time_step(0.5);
# $filter2->step_up(10);
# $filter2->step_down(2);

$filter3->control(13); # delay time
# $filter3->range_bottom(10);
# $filter3->range_top(100);
# $filter3->range_step(2);
# $filter3->time_step(0.4);
# $filter3->step_up(10);
# $filter3->step_down(2);

$control->add_filter('scatter', ['all'], $filter1->curry::scatter);
$control->add_filter('breathe', ['all'], $filter2->curry::breathe);
$control->add_filter('stair_step', ['all'], $filter3->curry::stair_step);

$control->run;

# ...and now trigger a MIDI message!
