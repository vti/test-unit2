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

    my $context = $self->{_context} = {test_case => $test_case};

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

    my $message;
    if (!ref $cb) {
        $message = $cb;
        $cb      = pop;
    }

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
            $message ||= "error message does not match $re";
            return $self->assert(scalar($e =~ m/$re/), $message);
        }

        if ($isa) {
            $message ||=
              qq{exception isa expected '$isa', got '} . ref($e) . qq{'};
            return $self->assert(blessed($e) && $e->isa($isa), $message);
        }

        return $self->assert(1);
    };

    $message ||= 'no exception was raised';
    return $self->assert(0, $message);
}

sub assert_deep_equals {
    my $self = shift;
    my ($expected, $got, $message) = @_;

    my $context = [];
    my $ok = $self->_assert_deep_equals($expected, $got, $context, \$message);

    return $self->assert($ok, $message);
}

sub _assert_deep_equals {
    my $self = shift;
    my ($expected, $got, $context_ref, $message_ref) = @_;

    my $ok = 0;
    if (ref($expected)) {
        if (!ref($got)) {
            $ok           = 0;
            my $context = join '', @$context_ref;
            $$message_ref = qq{\$got$context expected to be a } . ref($expected) . ' reference';
        }
        elsif (ref($expected) ne ref($got)) {
            $ok           = 0;
            my $context = join '', @$context_ref;
            $$message_ref = qq{\$got$context expected to be a } . ref($expected) . ' reference';
        }
        elsif (ref($expected) eq 'HASH') {
            foreach my $key (keys %$got) {
                push @$context_ref, "->{$key}";
                if (!exists $expected->{$key}) {
                    my $context = join '', @$context_ref;
                    $$message_ref = qq/unexpected key \$got$context/;
                    return 0;
                }
                pop @$context_ref;
            }

            foreach my $key (keys %$expected) {
                push @$context_ref, "->{$key}";
                if (!exists $got->{$key}) {
                    my $context = join '', @$context_ref;
                    $$message_ref = qq/key does not exist \$got$context/;
                    return 0;
                }
                pop @$context_ref;
            }

            foreach my $key (keys %$expected) {
                push @$context_ref, "->{$key}";

                unless (
                    $self->_assert_deep_equals(
                        $expected->{$key}, $got->{$key},
                        $context_ref,      $message_ref
                    )
                  )
                {
                    if (!$$message_ref) {
                        my $expected_value =
                          defined $expected->{$key}
                          ? qq{'$expected->{$key}'}
                          : 'undef';
                        my $got_value =
                          defined $got->{$key}
                          ? qq{'$got->{$key}'}
                          : 'undef';
                        my $context = join '', @$context_ref;
                        $$message_ref = qq{\$expected$context = $expected_value}
                          . qq{, \$got$context = $got_value};
                    }
                    return 0;
                }

                pop @$context_ref;
            }

            $ok = 1;
        }
        elsif (ref($expected) eq 'ARRAY') {
            if (@$expected != @$got) {
                $$message_ref =
                    'uneven array length, expected '
                  . (@$expected) . ' got '
                  . (@$got);
                return 0;
            }

            for (my $i = 0; $i < @$expected; $i++) {
                return 0
                  unless $self->_assert_deep_equals($expected->[$i],
                    $got->[$i], $context_ref, $message_ref);
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
    my ($expected, $got, $message) = @_;

    my $ok = 0;
    if (!defined($expected) && !defined($got)) {
        $ok = 1;
    }
    elsif (!defined($expected) || !defined($got)) {
        $ok = 0;

        if (defined($expected)) {
            $message = "expected to be defined";
        }
        else {
            $message = "expected to be undef";
        }
    }
    elsif ($expected eq $got) {
        $ok = 1;
    }
    else {
        $message = "expected '$expected', got '$got'";
    }

    return $self->assert($ok, $message);
}

sub assert_str_not_equals {
    my $self = shift;
    my ($expected, $got, $message) = @_;

    my $ok = 0;
    if (!defined($expected) && !defined($got)) {
        $ok = 0;

        $message = "expected one to be defined";
    }
    elsif (!defined($expected) || !defined($got)) {
        $ok = 1;
    }
    elsif ($expected ne $got) {
        $ok = 1;
    }
    else {
        $message = "expected '$got' to be different from '$expected'";
    }

    return $self->assert($ok, $message);
}

sub assert_num_equals {
    my $self = shift;
    my ($expected, $got, $message) = @_;

    my $ok = 0;
    if (!defined($expected) && !defined($got)) {
        $ok = 1;
    }
    elsif (!defined($expected) || !defined($got)) {
        $ok = 0;

        if (defined($expected)) {
            $message = "expected to be defined";
        }
        else {
            $message = "expected to be undef";
        }
    }
    elsif ($expected == $got) {
        $ok = 1;
    }
    else {
        $message = "expected $expected, got $got";
    }

    return $self->assert($ok, $message);
}

sub assert_num_not_equals {
    my $self = shift;
    my ($expected, $got, $message) = @_;

    my $ok = 0;
    if (!defined($expected) && !defined($got)) {
        $ok = 0;

        $message = "expected one to be defined";
    }
    elsif (!defined($expected) || !defined($got)) {
        $ok = 1;
    }
    elsif ($expected != $got) {
        $ok = 1;
    }
    else {
        $message = "expected $got to be different from $expected";
    }

    return $self->assert($ok, $message);
}

sub assert_null {
    my $self = shift;
    my ($got, $message) = @_;

    $message ||= 'excepted to be undef';

    return $self->assert(!defined($got), $message);
}

sub assert_not_null {
    my $self = shift;
    my ($got, $message) = @_;

    $message ||= 'expected to be defined';

    return $self->assert(defined($got), $message);
}

sub assert_matches {
    my $self = shift;
    my ($re, $got, $message) = @_;

    $message ||= qq{expected to match $re};

    return $self->assert(scalar($got =~ m/$re/), $message);
}

sub assert_not_matches {
    my $self = shift;
    my ($re, $got, $message) = @_;

    $message ||= qq{expected not to match $re};

    return $self->assert(scalar($got !~ m/$re/), $message);
}

sub assert {
    my $self = shift;
    my ($ok, $message) = @_;

    $ok = !!$ok;

    $message ||= "expected to be true";

    my $context = $self->{_context};
    if ($context && %$context) {
        if (exists $context->{methods}->[-1]->{ok}) {
            $context->{methods}->[-1]->{ok} = 0 unless $ok;
        }
        else {
            $context->{methods}->[-1]->{ok} = $ok ? 1 : 0;
        }

        $context->{methods}->[-1]->{message} = $message;

        if (exists $context->{ok}) {
            $context->{ok} = 0 unless $ok;
        }
        else {
            $context->{ok} = $ok ? 1 : 0;
        }

        $context->{methods}->[-1]->{caller} =
          (caller(0))[1] . ':' . (caller(0))[2];
        $context->{methods}->[-1]->{assert} = (caller(0))[3] =~ m/([^:])+$/;

        my $i = 0;
        while (my @caller = caller($i++)) {
            if ($caller[0] eq $context->{test_case}) {
                my $assert = $caller[3];
                $assert =~ s{.*::}{};
                $context->{methods}->[-1]->{caller} =
                  $caller[1] . ':' . $caller[2];
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
