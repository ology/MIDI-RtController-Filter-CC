#!/usr/bin/env perl

# PERL_FUTURE_DEBUG=1 perl eg/control-change.pl

use curry;
use MIDI::RtController ();
use MIDI::RtController::Filter::CC ();

my $input_names = shift || 'keyboard,pad,joystick'; # midi controller devices
my $output_name = shift || 'usb'; # midi output

my $inputs = [ split /,/, $input_names ];

my $control = MIDI::RtController->new(
    input   => $inputs->[0],
    output  => $output_name,
    verbose => 1,
);

for my $name (@$inputs[1 .. $#$inputs]) {
    MIDI::RtController->new(
        input    => $name,
        loop     => $control->loop,
        midi_out => $control->midi_out,
        verbose  => 1,
    );
}

my %filters = (
    # 1 => { # mod-wheel
        # type => 'breathe',
        # time_step => 0.1,
    # },
    # 13 => { # delay time
        # type => 'breathe',
        # time_step => 0.5,
        # range_bottom => 10,
        # range_top => 100,
    # },
    # 14 => { # waveform modulate
        # type => 'breathe',
        # time_step => 0.25,
        # range_bottom => 10,
        # range_top => 100,
    # },
    22 => { # noise
        type => 'ramp',
        # time_step => 0.2,
        # range_bottom => 0,
        # range_top => 80,
    },
    # 26 => { # filter e.g. release
        # type => 'breathe',
        # time_step => 0.5,
        # range_bottom => 10,
        # range_top => 127,
    # },
    # 77 => {  # oscillator 1 waveform
        # type => 'single',
        # value => 18, # 0: sawtooth, 18: square
    # },
);

for my $cc (keys %filters) {
    my %params = $filters{$cc}->%*;
    my $type = delete $params{type};
    my $filter = MIDI::RtController::Filter::CC->new(rtc => $control);
    $filter->control($cc);
    for my $param (keys %params) {
        $filter->$param($params{$param});
    }
    my $method = "curry::$type";
    $control->add_filter($type, ['all'], $filter->$method);
}

$control->run;

# ...and now trigger a MIDI message!
