package Test::Unit2::TestCase;

use strict;
use warnings;

sub new {
    my $class = shift;

    my $self = {};
    bless $self, $class;

    $self->{_tests_run} = 0;

    return $self;
}

sub execute {
    my $self = shift;

    my $test_case = ref($self);

    my @test_methods;
    foreach my $test_class ($test_case, reverse @{$class::ISA || []}) {
        my @parent_test_methods = $self->_find_test_methods($test_class);
        foreach my $parent_test_method (@parent_test_methods) {
            push @test_methods, $parent_test_method
              unless grep { $parent_test_method eq $_ } @test_methods;
        }
    }

    $self->{_test_case_ok} = 1;

    $self->notify('before:test_case', $test_case);

    foreach my $test_method (@test_methods) {
        $self->{_test_method_ok} = 1;

        $self->notify('before:test_method', $test_method);

        my $e;

        local $@;
        eval { $self->$test_method; 1 } or do { $e = $@ };

        if ($e) {
            $self->{_test_method_ok} = 0;
            $self->notify('after:test_method', error => $e);
        }
        else {
            $self->notify('after:test_method', ok => $self->{_test_method_ok});
        }
    }

    $self->notify('after:test_case', $self->{_test_case_ok});

    return $self;
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
            }

            foreach my $key (keys %$expected) {
                return 0 unless $self->_assert_deep_equals($expected->{$key}, $got->{$key});
            }

            $ok = 1;
        }
        elsif (ref($expected) eq 'ARRAY') {
            return 0 unless @$expected == @$got;

            for (my $i = 0; $i < @$expected; $i++) {
                return 0 unless $expected->[$i] eq $got->[$i];
            }

            $ok = 1;
        }
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

sub assert {
    my $self = shift;
    my ($ok) = @_;

    $ok = !!$ok;

    $self->notify('after:assert', $ok);

    $self->{_test_method_ok} = 0 unless $ok;
    $self->{_test_case_ok}   = 0 unless $ok;

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

sub _find_test_methods {
    my $self = shift;
    my ($class) = @_;

    no strict;
    return grep { /^(?:test|should)_/ } keys %{$class . '::'};
}

1;
