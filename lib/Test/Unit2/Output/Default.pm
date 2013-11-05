package Test::Unit2::Output::Default;

use strict;
use warnings;

use Time::HiRes ();
use Benchmark ();
use Term::ReadKey ();

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

    my ($cols) = Term::ReadKey::GetTerminalSize();
    my $right_offset = 14;

    my $start_time;
    my $end_time;

    $test_case->bind(
        'before:test_method' => sub {
            $start_time = Time::HiRes::time();
        });

    $test_case->bind(
        'after:test_method' => sub {
            my ($context) = @_;

            $end_time = Time::HiRes::time();

            $self->{tests}++;

            my $method_context = $context->{methods}->[-1];

            my $printed = $self->_print($context->{test_case} . ' - ' . $method_context->{test_method});

            my $description;

            if (my $error = $method_context->{error}) {
                push @{$self->{errors}}, {%$context, method => $method_context};

                $printed += $self->_print("." x ($cols - $printed - $right_offset));
                $printed += $self->_print("ERROR");

                $description = $error;
            }
            elsif ($method_context->{ok}) {
                $printed += $self->_print(" " x ($cols - $printed - $right_offset + 3));
                $printed += $self->_print("OK");
            }
            else {
                push @{$self->{fails}}, {%$context, method => $method_context};

                $printed += $self->_print("." x ($cols - $printed - $right_offset + 1));
                $printed += $self->_print("FAIL");
            }

            print " " x ($cols - $printed - 8);
            print sprintf('%.03f', $end_time - $start_time), "s";
            print "\n";

            if ($description) {
                print $description, "\n";
            }
        }
    );
}

sub finalize {
    my $self = shift;

    $self->{end_time} = Benchmark->new;

    my $run_time = Benchmark::timediff($self->{end_time}, $self->{start_time});
    print "\n", "Time: ", Benchmark::timestr($run_time), "\n";

    if (my @errors = @{$self->{errors}}) {
        my $counter = 1;
        print "\nERRORS:\n";
        foreach my $error (@errors) {
            print "$counter) $error->{test_case} - $error->{method}->{test_method}\n";
            print $error->{method}->{error};
            $counter++;
        }
    }

    if (my @fails = @{$self->{fails}}) {
        my $counter = 1;
        print "\nFAILS:\n";
        foreach my $fail (@fails) {
            print "$counter) $fail->{method}->{caller} - $fail->{method}->{test_method} ($fail->{test_case})\n";
            print $fail->{method}->{assert}, "\n";
            $counter++;
        }
    }

    my $result = "OK";
    if (@{$self->{errors}} || @{$self->{fails}}) {
        $result = "FAIL";
    }

    print "\n", $result, " ($self->{tests} tests)\n";
}

sub _print {
    my $self = shift;
    my ($string) = @_;

    print $string;

    return length($string);
}

1;
