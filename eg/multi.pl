#!/usr/bin/env perl

# PERL_FUTURE_DEBUG=1 perl eg/control-change.pl

use curry;
use MIDI::RtController ();
use MIDI::RtController::Filter::CC ();
use Object::Destroyer ();

my $input_names = shift || 'keyboard,pad,joystick'; # midi controller devices
my $output_name = shift || 'usb'; # midi output

my %filters = (
    1 => { # mod-wheel
        port => 'pad',
        event => 'control_change', #[qw(note_on note_off)],
        trigger => 25,
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
    22 => { # noise
        port => 'joystick',
        trigger => 25,
        type => 'ramp',
        time_step => 0.5,
        range_bottom => 0,
        range_top => 40,
    },
    # 26 => { # filter e.g. release
        # port => 'joystick',
        # type => 'breathe',
        # time_step => 0.5,
        # range_bottom => 10,
        # range_top => 127,
    # },
    77 => { # oscillator 1 waveform
        port => 'joystick',
        trigger => 26,
        value => 54, # 0: saw, 18: squ, 36: tri, 54: sin, 72 vox
    },
    14 => { # waveform modulate
        port => 'joystick',
        type => 'breathe',
        trigger => 27,
        time_step => 0.25,
        range_bottom => 10,
        range_top => 100,
    },
);

my @inputs = split /,/, $input_names;
my $name = $inputs[0];

# open the inputs
my %controllers;
my $control = MIDI::RtController->new(
    input   => $name,
    output  => $output_name,
    verbose => 1,
);
$controllers{$name}->{rtc} = $control;
for my $i (@inputs[1 .. $#inputs]) {
    $controllers{$i}->{rtc} = MIDI::RtController->new(
        input    => $i,
        loop     => $control->loop,
        midi_out => $control->midi_out,
        verbose  => 1,
    );
}

# add the filters
for my $cc (keys %filters) {
    my %params = $filters{$cc}->%*;
    my $port   = delete $params{port}  || $control->input;
    my $type   = delete $params{type}  || 'single';
    my $event  = delete $params{event} || 'all';
    my $filter = MIDI::RtController::Filter::CC->new(
        rtc => $controllers{$port}->{rtc}
    );
    $filter->control($cc);
    for my $param (keys %params) {
        $filter->$param($params{$param});
    }
    my $method = "curry::$type";
    $controllers{$port}->{rtc}->add_filter($type, $event => $filter->$method);
}

$control->run;

# ...and now trigger a MIDI message!

# XXX maybe needed?
END: {
    for my $i (@inputs) {
        # for my $j ($controllers{$i}->{filters}->@*) {
            # Object::Destroyer->new($j, 'delete');
        # }
        Object::Destroyer->new($controllers{$i}->{rtc}, 'delete');
    }
}
