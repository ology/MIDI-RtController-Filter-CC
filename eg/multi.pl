#!/usr/bin/env perl

# PERL_FUTURE_DEBUG=1 perl eg/control-change.pl

use curry;
use MIDI::RtController ();
use MIDI::RtController::Filter::CC ();
# use Object::Destroyer ();

my $input_names = shift || 'keyboard,pad,joystick'; # midi controller devices
my $output_name = shift || 'usb'; # midi output

my %filters = (
    1 => { # mod-wheel
        port => 'pad',
        type => 'breathe',
        time_step => 0.25,
    },
    # 13 => { # delay time
        # port => 'joystick',
        # type => 'breathe',
        # time_step => 0.5,
        # range_bottom => 10,
        # range_top => 100,
    # },
    # 14 => { # waveform modulate
        # port => 'joystick',
        # type => 'breathe',
        # time_step => 0.25,
        # range_bottom => 10,
        # range_top => 100,
    # },
    22 => { # noise
        port => 'joystick',
        type => 'ramp',
        time_step => 0.5,
        range_bottom => 0,
        range_top => 30,
    },
    # 26 => { # filter e.g. release
        # port => 'joystick',
        # type => 'breathe',
        # time_step => 0.5,
        # range_bottom => 10,
        # range_top => 127,
    # },
    # 77 => {  # oscillator 1 waveform
        # port => 'joystick',
        # type => 'single',
        # value => 18, # 0: sawtooth, 18: square
    # },
);

my $inputs = [ split /,/, $input_names ];

# open the inputs
my $control = MIDI::RtController->new(
    input   => $inputs->[0],
    output  => $output_name,
    verbose => 1,
);
my %controllers;
$controllers{ $inputs->[0] } = $control;
for my $name (@$inputs[1 .. $#$inputs]) {
    $controllers{$name} = MIDI::RtController->new(
        input    => $name,
        loop     => $control->loop,
        midi_out => $control->midi_out,
        verbose  => 1,
    );
}

# add the filters
for my $cc (keys %filters) {
    my %params = $filters{$cc}->%*;
    my $port = delete $params{port};
    my $type = delete $params{type};
    my $filter = MIDI::RtController::Filter::CC->new(rtc => $controllers{$port});
    $filter->control($cc);
    for my $param (keys %params) {
        $filter->$param($params{$param});
    }
    my $method = "curry::$type";
    $controllers{$port}->add_filter($type, ['all'], $filter->$method);
}

$control->run;

# ...and now trigger a MIDI message!

# END: {
    # Object::Destroyer->new($control, 'delete');
# }
