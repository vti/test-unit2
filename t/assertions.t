use strict;
use warnings;

use Test::More;

use Test::Unit2::TestCase;

subtest 'assert' => sub {
    my $case = _build_case();

    ok $case->assert(1);

    ok !$case->assert(0);
};

subtest 'assert_str_equals' => sub {
    my $case = _build_case();

    ok $case->assert_str_equals('expected', 'expected');
    ok $case->assert_str_equals(undef,      undef);
    ok $case->assert_str_equals(0,          0);

    ok !$case->assert_str_equals('expected', undef);
    ok !$case->assert_str_equals('expected', 'got');
};

subtest 'assert_str_not_equals' => sub {
    my $case = _build_case();

    ok !$case->assert_str_not_equals('expected', 'expected');
    ok !$case->assert_str_not_equals(undef,      undef);
    ok !$case->assert_str_not_equals(0,          0);

    ok $case->assert_str_not_equals('expected', undef);
    ok $case->assert_str_not_equals('expected', 'got');
};

subtest 'assert_num_equals' => sub {
    my $case = _build_case();

    ok $case->assert_num_equals(1,     1);
    ok $case->assert_num_equals(undef, undef);

    ok !$case->assert_num_equals(1, undef);
    ok !$case->assert_num_equals(1, 2);
};

subtest 'assert_num_not_equals' => sub {
    my $case = _build_case();

    ok $case->assert_num_not_equals(1,     2);
    ok $case->assert_num_not_equals(undef, 1);

    ok !$case->assert_num_not_equals(1, 1);
    ok !$case->assert_num_not_equals(undef, undef);
};

subtest 'assert_raises' => sub {
    my $case = _build_case();

    ok $case->assert_raises(sub { die 'here' });
    ok $case->assert_raises(qr/here/, sub { die 'here' });
    ok $case->assert_raises('Exception', qr/here/, sub { die Exception->new('here') });
    ok $case->assert_raises(qr/here/, sub { die Exception->new('here') });
    ok $case->assert_raises('Exception', sub { die Exception->new });

    ok! $case->assert_raises(sub { });
    ok! $case->assert_raises(qr/here/, sub { die 'haha' });
    ok! $case->assert_raises('Exception', qr/here/, sub { die Exception->new('haha') });
    ok! $case->assert_raises(qr/here/, sub { die Exception->new('haha') });
    ok! $case->assert_raises('AnotherException', sub { die Exception->new });
};

subtest 'assert_deep_equals' => sub {
    my $case = _build_case();

    ok $case->assert_deep_equals({}, {});
    ok $case->assert_deep_equals({foo => 'bar'}, {foo => 'bar'});
    ok $case->assert_deep_equals({foo => {bar => 'baz'}},
        {foo => {'bar' => 'baz'}});
    ok $case->assert_deep_equals([], []);
    ok $case->assert_deep_equals([1, 2, 3], [1, 2, 3]);
    ok $case->assert_deep_equals([{foo => 'bar'}], [{foo => 'bar'}]);
    ok $case->assert_deep_equals({foo => undef}, {foo => undef});

    ok !$case->assert_deep_equals([], 'foo');
    ok !$case->assert_deep_equals([], {});
    ok !$case->assert_deep_equals({}, []);
    ok !$case->assert_deep_equals({foo => 'bar'}, {foo => 'baz'});
    ok !$case->assert_deep_equals({foo => 'bar'}, {foo => 'bar', hi => 'there'});
    ok !$case->assert_deep_equals({foo => {bar => 'qux'}},
        {foo => {'bar' => 'baz'}});
    ok !$case->assert_deep_equals([1, 2], [1, 2, 3]);
    ok !$case->assert_deep_equals({foo => undef}, {foo => 1});
};

subtest 'assert_null' => sub {
    my $case = _build_case();

    ok $case->assert_null(undef);

    ok !$case->assert_null(1);
};

subtest 'assert_not_null' => sub {
    my $case = _build_case();

    ok $case->assert_not_null(1);

    ok !$case->assert_not_null(undef);
};

subtest 'assert_matches' => sub {
    my $case = _build_case();

    ok $case->assert_matches(qr/\d+/, 1);

    ok !$case->assert_matches(qr/\d+/, 'abc');
};

subtest 'assert_not_matches' => sub {
    my $case = _build_case();

    ok $case->assert_not_matches(qr/\d+/, 'abc');

    ok !$case->assert_not_matches(qr/\d+/, 1);
};

sub _build_case { Test::Unit2::TestCase->new }

done_testing;

package Exception;

use overload '""' => \&to_string, fallback => 1;
sub new {
    my $class = shift;
    my ($message) = @_;

    my $self = {message => $message};
    bless $self, $class;

    return $self;
}
sub to_string { shift->{message} }
