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

my $filter = MIDI::RtController::Filter::CC->new(rtc => $control);

# $control->add_filter('breathe', ['all'], $filter->curry::breathe);

$filter->time_step(500_000);
$control->add_filter('scatter', ['all'], $filter->curry::scatter);

$control->run;

# ...and now trigger a MIDI message!
