#!/usr/bin/env perl

use MIDI::RtController ();
use MIDI::RtController::Filter::CC ();

my $in  = shift || 'pad'; # keyboard controller
my $out = shift || 'usb'; # midi output

my @filters = (
    { # cutoff
        port => $in,
        event => 'control_change',
        control => 74, # CUTOFF
        trigger => 12, # X axis
    },
    { # resonance
        port => $in,
        event => 'control_change',
        control => 71, # RESONANCE
        trigger => 13, # Y axis
    },
);

# open the inputs
my $controller = MIDI::RtController->new(
    input   => $in,
    output  => $out,
    verbose => 1,
);

MIDI::RtController::Filter::CC::add_filters(\@filters, { $in => $controller });

$controller->run;

# ...and now trigger a MIDI message!
