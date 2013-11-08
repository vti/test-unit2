package Test::Unit2::TestCase;

use strict;
use warnings;

use Scalar::Util qw(blessed);

sub new {
    my $class = shift;

    my $self = {};
    bless $self, $class;

    return $self;
}

sub set_up    { }
sub tear_down { }

sub execute {
    my $self = shift;

    my $test_case = ref($self);

    my @test_methods = $self->_find_test_methods_recursive($test_case);

    my $context = $self->{_context} = {
        test_case => $test_case
    };

    $self->notify('before:test_case', $context);

    foreach my $test_method (@test_methods) {
        push @{$context->{methods}}, {test_method => $test_method};

        $self->set_up;

        $self->notify('before:test_method', $context);

        my $e;

        local $@;
        eval { $self->$test_method; 1 } or do { $e = $@ };

        if ($e) {
            $context->{ok}                     = 0;
            $context->{methods}->[-1]->{ok}    = 0;
            $context->{methods}->[-1]->{error} = $e;
        }

        $self->notify('after:test_method', $context);

        $self->tear_down;
    }

    $self->notify('after:test_case', $context);

    return $self;
}

sub assert_raises {
    my $self = shift;
    my $cb   = pop;

    my ($isa, $re);

    if (@_ == 2) {
        ($isa, $re) = @_;
    }
    elsif (@_ == 1) {
        if (ref $_[0] eq 'Regexp') {
            $re = $_[0];
        }
        else {
            $isa = $_[0];
        }
    }

    eval { $cb->(); 1 } or do {
        my $e = $@;

        if ($re) {
            return $self->assert($e =~ m/$re/);
        }

        if ($isa) {
            return $self->assert(blessed($e) && $e->isa($isa));
        }

        return $self->assert(1);
    };

    return $self->assert(0);
}

sub assert_deep_equals {
    my $self = shift;
    my ($expected, $got) = @_;

    my $ok = $self->_assert_deep_equals($expected, $got);

    return $self->assert($ok);
}

sub _assert_deep_equals {
    my $self = shift;
    my ($expected, $got) = @_;

    my $ok = 0;
    if (ref($expected)) {
        if (!ref($got)) {
            $ok = 0;
        }
        elsif (ref($expected) ne ref($got)) {
            $ok = 0;
        }
        elsif (ref($expected) eq 'HASH') {
            my @expected_keys = sort keys %$expected;
            my @got_keys      = sort keys %$got;
            return 0 unless @expected_keys == @got_keys;

            for (my $i = 0; $i < @expected_keys; $i++) {
                return 0 unless $expected_keys[$i] eq $got_keys[$i];
                return 0 unless $self->_assert_deep_equals($expected_keys[$i], $got_keys[$i]);
            }

            foreach my $key (keys %$expected) {
                return 0
                  unless $self->_assert_deep_equals($expected->{$key},
                    $got->{$key});
            }

            $ok = 1;
        }
        elsif (ref($expected) eq 'ARRAY') {
            return 0 unless @$expected == @$got;

            for (my $i = 0; $i < @$expected; $i++) {
                return 0 unless $self->_assert_deep_equals($expected->[$i], $got->[$i]);
            }

            $ok = 1;
        }
    }
    elsif (!defined($expected) && !defined($got)) {
        return 1;
    }
    elsif (!defined($expected) || !defined($got)) {
        return 0;
    }
    else {
        $ok = $expected eq $got;
    }

    return $ok;
}

sub assert_str_equals {
    my $self = shift;
    my ($expected, $got) = @_;

    my $ok = 0;
    if (!defined($expected) && !defined($got)) {
        $ok = 1;
    }
    elsif (!defined($expected) || !defined($got)) {
        $ok = 0;
    }
    elsif ($expected eq $got) {
        $ok = 1;
    }

    return $self->assert($ok);
}

sub assert_str_not_equals {
    my $self = shift;
    my ($expected, $got) = @_;

    my $ok = 0;
    if (!defined($expected) && !defined($got)) {
        $ok = 0;
    }
    elsif (!defined($expected) || !defined($got)) {
        $ok = 1;
    }
    elsif ($expected ne $got) {
        $ok = 1;
    }

    return $self->assert($ok);
}

sub assert_num_equals {
    my $self = shift;
    my ($expected, $got) = @_;

    my $ok = 0;
    if (!defined($expected) && !defined($got)) {
        $ok = 1;
    }
    elsif (!defined($expected) || !defined($got)) {
        $ok = 0;
    }
    elsif ($expected == $got) {
        $ok = 1;
    }

    return $self->assert($ok);
}

sub assert_num_not_equals {
    my $self = shift;
    my ($expected, $got) = @_;

    my $ok = 0;
    if (!defined($expected) && !defined($got)) {
        $ok = 0;
    }
    elsif (!defined($expected) || !defined($got)) {
        $ok = 1;
    }
    elsif ($expected != $got) {
        $ok = 1;
    }

    return $self->assert($ok);
}

sub assert_null {
    my $self = shift;
    my ($got) = @_;

    return $self->assert(!defined($got));
}

sub assert_not_null {
    my $self = shift;
    my ($got) = @_;

    return $self->assert(defined($got));
}

sub assert_matches {
    my $self = shift;
    my ($re, $got) = @_;

    return $self->assert($got =~ m/$re/);
}

sub assert_not_matches {
    my $self = shift;
    my ($re, $got) = @_;

    return $self->assert($got !~ m/$re/);
}

sub assert {
    my $self = shift;
    my ($ok) = @_;

    $ok = !!$ok;

    my $context = $self->{_context};
    if ($context && %$context) {
        if (exists $context->{methods}->[-1]->{ok}) {
            $context->{methods}->[-1]->{ok} = 0 unless $ok;
        }
        else {
            $context->{methods}->[-1]->{ok} = $ok ? 1 : 0;
        }

        if (exists $context->{ok}) {
            $context->{ok} = 0 unless $ok;
        }
        else {
            $context->{ok} = $ok ? 1 : 0;
        }

        $context->{methods}->[-1]->{caller} = (caller(0))[1]. ':'. (caller(0))[2];
        $context->{methods}->[-1]->{assert} = (caller(0))[3] =~ m/([^:])+$/;

        my $i = 0;
        while (my @caller = caller($i++)) {
            if ($caller[0] eq $context->{test_case}) {
                my $assert = $caller[3];
                $assert =~ s{.*::}{};
                $context->{methods}->[-1]->{caller} = $caller[1]. ':'. $caller[2];
                $context->{methods}->[-1]->{assert} = $assert;

                last;
            }
        }
    }

    $self->notify('after:assert', $context);

    return $ok;
}

sub bind {
    my $self = shift;
    my ($event, $cb) = @_;

    push @{$self->{_listeners}->{$event}}, $cb;

    return $self;
}

sub notify {
    my $self = shift;
    my ($event, @args) = @_;

    foreach my $listeners (@{$self->{_listeners}->{$event}}) {
        $listeners->(@args);
    }

    return $self;
}

sub _find_test_methods_recursive {
    my $self = shift;
    my ($class) = @_;

    my @classes = (
        $class,
        do { no strict; reverse @{"$class\::ISA"} }
    );

    my @test_methods;
    foreach my $test_class (@classes) {
        my @parent_test_methods = $self->_find_test_methods($test_class);
        foreach my $parent_test_method (@parent_test_methods) {
            push @test_methods, $parent_test_method
              unless grep { $parent_test_method eq $_ } @test_methods;
        }
    }

    return @test_methods;
}

sub _find_test_methods {
    my $self = shift;
    my ($class) = @_;

    no strict;
    return sort grep { /^(?:test|should)_/ } keys %{$class . '::'};
}

1;
