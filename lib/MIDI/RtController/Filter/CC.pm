package MIDI::RtController::Filter::CC;

# ABSTRACT: Control-change based RtController filters

our $VERSION = '0.0301';

use v5.36;

use strictures 2;
use Data::Dumper::Compact qw(ddc);
use IO::Async::Timer::Periodic;
use IO::Async::Loop;
use Iterator::Breathe ();
use Moo;
use Time::HiRes qw(usleep);
use Types::MIDI qw(Channel Velocity);
use Types::Common::Numeric qw(PositiveNum);
use Types::Standard qw(Bool Num);
use namespace::clean;

=head1 SYNOPSIS

  use curry;
  use MIDI::RtController ();
  use MIDI::RtController::Filter::CC ();

  my $control = MIDI::RtController->new(
    input  => 'keyboard',
    output => 'usb',
  );

  my $filter = MIDI::RtController::Filter::CC->new(rtc => $control);

  $filter->control(1); # CC#01 = mod-wheel
  $filter->channel(0);
  $filter->range_bottom(10);
  $filter->range_top(100);
  $filter->range_step(2);
  $filter->time_step(0.25);

  $control->add_filter('breathe', all => $filter->curry::breathe);

  $control->run;

=head1 DESCRIPTION

C<MIDI::RtController::Filter::CC> is a (growing) collection of
control-change based L<MIDI::RtController> filters.

=head2 Making filters

All filter methods must accept the object, a MIDI device name, a
delta-time, and a MIDI event ARRAY reference, like:

  sub breathe ($self, $device, $delta, $event) {
    return 0 if $self->running;
    my ($event_type, $chan, $control, $value) = $event->@*;
    ...
    return $boolean;
  }

A filter also must return a boolean value. This tells
L<MIDI::RtController> to continue processing other known filters or
not.

=head1 ATTRIBUTES

=head2 rtc

  $rtc = $filter->rtc;

The required L<MIDI::RtController> instance provided in the
constructor.

=cut

has rtc => (
    is  => 'ro',
    isa => sub { die 'Invalid rtc' unless ref($_[0]) eq 'MIDI::RtController' },
    required => 1,
);

=head2 channel

  $channel = $filter->channel;
  $filter->channel($number);

The current MIDI channel value between C<0> and C<15>.

Default: C<0>

=cut

has channel => (
    is      => 'rw',
    isa     => Channel,
    default => 0,
);

=head2 control

  $control = $filter->control;
  $filter->control($number);

Return or set the control change number between C<0> and C<127>.

Default: C<1> (mod-wheel)

=cut

has control => (
    is      => 'rw',
    isa     => Velocity, # no CC# in Types::MIDI yet
    default => 1,
);

=head2 initial_point

  $initial_point = $filter->initial_point;
  $filter->initial_point($number);

Return or set the control change initial point number between C<0> and
C<127>.

Default: C<0>

=cut

has initial_point => (
    is      => 'rw',
    isa     => Velocity, # no CC# msg value in Types::MIDI yet
    default => 0,
);

=head2 range_bottom

  $range_bottom = $filter->range_bottom;
  $filter->range_bottom($number);

The current iteration lowest number value.

Default: C<0>

=cut

has range_bottom => (
    is      => 'rw',
    isa     => Num,
    default => 0,
);

=head2 range_top

  $range_top = $filter->range_top;
  $filter->range_top($number);

The current iteration highest number value.

Default: C<127>

=cut

has range_top => (
    is      => 'rw',
    isa     => Num,
    default => 127,
);

=head2 range_step

  $range_step = $filter->range_step;
  $filter->range_step($number);

A number greater than zero representing the current iteration step
size between B<bottom> and B<top>.

Default: C<1>

=cut

has range_step => (
    is      => 'rw',
    isa     => PositiveNum,
    default => 1,
);

=head2 time_step

  $time_step = $filter->time_step;
  $filter->time_step($number);

The current iteration step in seconds (probably fractions).

Default: C<0.25> (a quarter of a second)

=cut

has time_step => (
    is      => 'rw',
    isa     => PositiveNum,
    default => 0.25,
);

=head2 step_up

  $step_up = $filter->step_up;
  $filter->step_up($number);

The current iteration upward step.

Default: C<2>

=cut

has step_up => (
    is      => 'rw',
    isa     => Num,
    default => 2,
);

=head2 step_down

  $step_down = $filter->step_down;
  $filter->step_down($number);

The current iteration downward step.

Default: C<1>

=cut

has step_down => (
    is      => 'rw',
    isa     => Num,
    default => 1,
);

=head2 running

  $running = $filter->running;
  $filter->running($boolean);

Are we running a filter?

Default: C<0>

=cut

has running => (
    is      => 'rw',
    isa     => Bool,
    default => 0,
);

=head2 stop

  $stop = $filter->stop;
  $filter->stop($boolean);

Stop running a filter.

Default: C<0>

=cut

has stop => (
    is      => 'rw',
    isa     => Bool,
    default => 0,
);

=head1 METHODS

=head2 new

  $filter = MIDI::RtController::Filter::CC->new(%arguments);

Return a new C<MIDI::RtController::Filter::CC> object.

=head2 breathe

  $control->add_filter('breathe', all => $filter->curry::breathe);

This filter sets the B<running> flag, then iterates between the
B<range_bottom> and B<range_top> by B<range_step> increments, sending
a B<control> change message, over the MIDI B<channel> every iteration,
until B<stop> is seen.

Passing C<all> means that any MIDI event will cause this filter to be
triggered.

=cut

sub breathe ($self, $device, $dt, $event) {
    return 0 if $self->running;
    $self->running(1);

    my $it = Iterator::Breathe->new(
        bottom => $self->range_bottom,
        top    => $self->range_top,
        step   => $self->range_step,
    );

    $self->rtc->loop->add(
        IO::Async::Timer::Periodic->new(
            interval  => $self->time_step,
            on_tick => sub {
                $it->iterate;
                my $cc = [ 'control_change', $self->channel, $self->control, $it->i ];
                $self->rtc->send_it($cc);
            },
        )->start
    );

    return 0;
}

=head2 scatter

  $control->add_filter('scatter', all => $filter->curry::scatter);

This filter sets the B<running> flag, chooses a random number between
the B<range_bottom> and B<range_top>, and sends that as the value of a
B<control> change message, over the MIDI B<channel>, every iteration,
until B<stop> is seen.

The B<initial_point> is used as the first CC# message, then the
randomization takes over.

Passing C<all> means that any MIDI event will cause this filter to be
triggered.

=cut

sub scatter ($self, $device, $dt, $event) {
    return 0 if $self->running;
    $self->running(1);

    my $value  = $self->initial_point;
    my @values = ($self->range_bottom .. $self->range_top);

    $self->rtc->loop->add(
        IO::Async::Timer::Periodic->new(
            interval  => $self->time_step,
            on_tick => sub {
                my $cc = [ 'control_change', $self->channel, $self->control, $value ];
                $self->rtc->send_it($cc);
                $value = $values[ int rand @values ];
            },
        )->start
    );

    return 0;
}

=head2 stair_step

  $control->add_filter('stair_step', all => $filter->curry::stair_step);

This filter sets the B<running> flag, uses the B<initial_point> for
the fist CC# message, then adds B<step_up> or subtracts B<step_down>
from that number successively, sending the value as a B<control>
change message, over the MIDI B<channel>, every iteration, until
B<stop> is seen.

Passing C<all> means that any MIDI event will cause this filter to be
triggered.

=cut

sub stair_step ($self, $device, $dt, $event) {
    return 0 if $self->running;
    $self->running(1);

    my $it = Iterator::Breathe->new(
        bottom => $self->range_bottom,
        top    => $self->range_top,
    );

    my $value     = $self->initial_point;
    my $direction = 1; # up

    $self->rtc->loop->add(
        IO::Async::Timer::Periodic->new(
            interval  => $self->time_step,
            on_tick => sub {
                my $cc = [ 'control_change', $self->channel, $self->control, $value ];
                $self->rtc->send_it($cc);

                # compute the stair-stepping
                if ($direction) {
                    $it->step($self->step_up);
                }
                else {
                    $it->step(- $self->step_down);
                }

                # toggle the stair-step direction
                $direction = !$direction;

                # iterate the breathing
                $it->iterate;
                $value = $it->i;
                $value = $self->range_top    if $value >= $self->range_top;
                $value = $self->range_bottom if $value <= $self->range_bottom;
            },
        )->start
    );
    return 0;
}

1;
__END__

=head1 SEE ALSO

The F<eg/*.pl> program(s) in this distribution

L<Iterator::Breathe>

L<Moo>

L<Time::HiRes>

L<Types::Common::Numeric>

L<Types::MIDI>

L<Types::Standard>

=cut
