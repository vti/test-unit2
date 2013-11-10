use strict;
use warnings;

use Test::More;

use Test::Unit2::TestCase;

subtest 'assert' => sub {
    my $message = _run_case('$self->assert(0)');

    is($message, 'expected to be true');
};

subtest 'assert_str_equals' => sub {
    my $message = _run_case(q{$self->assert_str_equals('foo', 'bar')});
    is($message, q{expected 'foo', got 'bar'});

    $message = _run_case(q{$self->assert_str_equals(undef, 'bar')});
    is($message, q{expected to be undef});

    $message = _run_case(q{$self->assert_str_equals('foo', undef)});
    is($message, q{expected to be defined});
};

subtest 'assert_str_not_equals' => sub {
    my $message = _run_case(q{$self->assert_str_not_equals('foo', 'foo')});
    is($message, q{expected 'foo' to be different from 'foo'});

    $message = _run_case(q{$self->assert_str_not_equals(undef, undef)});
    is($message, q{expected one to be defined});
};

subtest 'assert_num_equals' => sub {
    my $message = _run_case(q{$self->assert_num_equals(1, 2)});
    is($message, q{expected 1, got 2});

    $message = _run_case(q{$self->assert_num_equals(undef, 2)});
    is($message, q{expected to be undef});

    $message = _run_case(q{$self->assert_num_equals(1, undef)});
    is($message, q{expected to be defined});
};

subtest 'assert_num_not_equals' => sub {
    my $message = _run_case(q{$self->assert_num_not_equals(1, 1)});
    is($message, q{expected 1 to be different from 1});

    $message = _run_case(q{$self->assert_num_not_equals(undef, undef)});
    is($message, q{expected one to be defined});
};

subtest 'assert_raises' => sub {
    my $message = _run_case(q{$self->assert_raises(sub { })});
    is($message, 'no exception was raised');

    $message = _run_case(q{$self->assert_raises(qr/here/, sub { die 'haha' })});
    like($message, qr/error message does not match /);

    $message = _run_case(q{$self->assert_raises('Exception', qr/here/, sub { die Exception->new('haha') })});
    like($message, qr/error message does not match /);

    $message = _run_case(q{$self->assert_raises(qr/here/, sub { die Exception->new('haha') })});
    like($message, qr/error message does not match /);

    $message = _run_case(q{$self->assert_raises('AnotherException', sub { die Exception->new })});
    is($message, q{exception isa expected 'AnotherException', got ''});
};

subtest 'assert_deep_equals' => sub {
    my $message;

    $message = _run_case(q{$self->assert_deep_equals([], 'foo')});
    is($message, 'expected to be a ARRAY reference');

    $message = _run_case(q{$self->assert_deep_equals([], {})});
    is($message, 'expected to be a ARRAY reference');

    $message = _run_case(q{$self->assert_deep_equals({}, [])});
    is($message, 'expected to be a HASH reference');

    $message = _run_case(q{$self->assert_deep_equals({foo => 'bar'}, {foo => 'baz'})});
    is($message, q{$expected->{foo} = 'bar', $got->{foo} = 'baz'});

    $message = _run_case(q{$self->assert_deep_equals({foo => 'bar'}, {foo => 'bar', hi => 'there'})});
    is($message, 'unexpected key $got->{hi}');

    $message = _run_case(q{$self->assert_deep_equals({foo => {bar => 'baz'}}, {foo => {bar => 'baz', hi => 'there'}})});
    is($message, 'unexpected key $got->{foo}->{hi}');

    $message = _run_case(q{$self->assert_deep_equals({foo => {bar => 'qux'}}, {foo => {'bar' => 'baz'}})});
    is($message, q/$expected->{foo}->{bar} = 'qux', $got->{foo}->{bar} = 'baz'/);

    $message = _run_case(q{$self->assert_deep_equals([1, 2], [1, 2, 3])});
    is($message, 'uneven array length, expected 2 got 3');

    $message = _run_case(q{$self->assert_deep_equals({foo => undef}, {foo => 1})});
    is($message, q{$expected->{foo} = undef, $got->{foo} = '1'});
};

subtest 'assert_null' => sub {
    my $message = _run_case(q{$self->assert_null(1)});
    is($message, q{excepted to be undef});
};

subtest 'assert_not_null' => sub {
    my $message = _run_case(q{$self->assert_not_null(undef)});
    is($message, q{expected to be defined});
};

subtest 'assert_matches' => sub {
    my $message = _run_case(q{$self->assert_matches(qr/\d+/, 'abc')});
    like($message, qr{expected to match });
};

subtest 'assert_not_matches' => sub {
    my $message = _run_case(q{$self->assert_not_matches(qr/\d+/, 123)});
    like($message, qr{expected not to match });
};

sub _run_case {
    my ($assert) = @_;
    my $name     = 'MyTest::' . int(rand(100));
    my $package  = <<"EOF";
package $name;
use base 'Test::Unit2::TestCase';
no warnings 'redefine';
sub test_me {
    my \$self = shift;
    $assert;
}
1;
EOF

    eval $package;

    my $case = $name->new;

    my $message;
    $case->bind(
        'after:assert' => sub {
            $message = $_[0]->{methods}->[-1]->{message};
        }
    );
    $case->execute;
    return $message;
}

done_testing;
