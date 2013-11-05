package Test::Unit2::Output::TAP;

use strict;
use warnings;

sub new {
    my $class = shift;

    my $self = {};
    bless $self, $class;

    $self->{counter} = 0;

    return $self;
}

sub watch {
    my $self = shift;
    my ($test_case) = @_;

    my $method_counter = 0;
    $test_case->bind(
        'after:test_method' => sub {
            my ($context) = @_;

            $method_counter++;

            my $method_context = $context->{methods}->[-1];

            my $ok = $method_context->{ok} ? 1 : 0;

            print "    ", $ok ? "ok" : "not ok",
              " $method_counter - $method_context->{test_method}\n";

            if (!$ok) {
                print "    ", "# Failed test\n";
            }
        }
    );

    $test_case->bind(
        'after:test_case' => sub {
            my ($context) = @_;

            $self->{counter}++;

            my $ok = $context->{ok} ? 1 : 0;

            print "    ", "1..$method_counter", "\n";
            print $ok ? "ok" : "not ok",
              " $self->{counter} - $context->{test_case}\n";
        }
    );
}

sub finalize {
    my $self = shift;

    print "1..$self->{counter}\n";
}

1;
