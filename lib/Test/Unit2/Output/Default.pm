package Test::Unit2::Output::Default;

use strict;
use warnings;

use Benchmark ();

sub new {
    my $class = shift;

    my $self = {};
    bless $self, $class;

    $self->{tests} = 0;
    $self->{fails}   = [];
    $self->{errors}  = [];

    return $self;
}

sub start {
    my $self = shift;

    $self->{start_time} = Benchmark->new;

    return $self;
}

sub watch {
    my $self = shift;
    my ($test_case) = @_;

    $test_case->bind(
        'after:test_method' => sub {
            my ($context) = @_;

            $self->{tests}++;

            my $method_context = $context->{methods}->[-1];

            print $context->{test_case} . ' - ' . $method_context->{test_method};

            print " ... ";

            if (my $error = $method_context->{error}) {
                push @{$self->{errors}}, $error;

                print "ERROR";
                print "\n", $error;
            }
            elsif ($method_context->{ok}) {
                print "OK";
            }
            else {
                push @{$self->{fails}}, "$context->{test_case} - $method_context->{test_method}";

                print "FAIL";
            }

            print "\n";
        }
    );
}

sub finalize {
    my $self = shift;

    $self->{end_time} = Benchmark->new;

    my $result = "OK";
    if (@{$self->{errors}} || @{$self->{fails}}) {
        $result = "FAIL";
    }

    print "\n", $result, " ($self->{tests} tests)\n";

    my $run_time = Benchmark::timediff($self->{end_time}, $self->{start_time});
    print "\n", "Time: ", Benchmark::timestr($run_time), "\n";

    if (my @errors = @{$self->{errors}}) {
        my $counter = 1;
        print "\nERRORS:\n";
        foreach my $error (@errors) {
            print "$counter) $error";
            $counter++;
        }
    }

    if (my @fails = @{$self->{fails}}) {
        my $counter = 1;
        print "\nFAILS:\n";
        foreach my $fail (@fails) {
            print "$counter) $fail\n";
            $counter++;
        }
    }
}

1;
