use strict;
use warnings;

use Test::More;

use Test::Unit2::TestCase;

subtest 'success notify before/after test_case' => sub {
    my @before;
    my @after;

    my $case = TestCaseSuccess->new;
    $case->bind('before:test_case', sub { push @before, @_ });
    $case->bind('after:test_case',  sub { push @after,  @_ });
    $case->execute;

    is_deeply(\@before, ['TestCaseSuccess']);
    is_deeply(\@after,  [1]);
};

subtest 'success notify before/after test_method' => sub {
    my @before;
    my @after;

    my $case = TestCaseSuccess->new;
    $case->bind('before:test_method', sub { push @before, @_ });
    $case->bind('after:test_method',  sub { push @after,  @_ });
    $case->execute;

    is_deeply(\@before, ['test_hi']);
    is_deeply(\@after, [ok => 1]);
};

subtest 'failure notify before/after test_case' => sub {
    my @before;
    my @after;

    my $case = TestCaseFailure->new;
    $case->bind('before:test_case', sub { push @before, @_ });
    $case->bind('after:test_case',  sub { push @after,  @_ });
    $case->execute;

    is_deeply(\@before, ['TestCaseFailure']);
    is_deeply(\@after,  [0]);
};

subtest 'failure notify before/after test_method' => sub {
    my @before;
    my @after;

    my $case = TestCaseFailure->new;
    $case->bind('before:test_method', sub { push @before, @_ });
    $case->bind('after:test_method',  sub { push @after,  @_ });
    $case->execute;

    is_deeply(\@before, ['test_hi']);
    is_deeply(\@after, [ok => 0]);
};

subtest 'call set_up/tear_down' => sub {
    my @RUN;

    {

        package TestCaseWithSetup;
        use base 'Test::Unit2::TestCase';

        sub new {
            my $self = shift->SUPER::new(@_);
            my (%params) = @_;

            $self->{run} = $params{run};

            return $self;
        }

        sub set_up {
            my $self = shift;

            push @{$self->{run}}, 'set_up';
        }

        sub tear_down {
            my $self = shift;

            push @{$self->{run}}, 'tear_down';
        }

        sub test_me {
            my $self = shift;
            push @{$self->{run}}, 'test';
        }
    }

    my $case = TestCaseWithSetup->new(run => \@RUN);
    $case->execute;

    is_deeply(\@RUN, ['set_up', 'test', 'tear_down']);
};

done_testing;

package TestCaseSuccess;
use base 'Test::Unit2::TestCase';

sub test_hi {
    my $self = shift;

    $self->assert_str_equals('expected', 'expected');
}

package TestCaseFailure;
use base 'Test::Unit2::TestCase';

sub test_hi {
    my $self = shift;

    $self->assert_str_equals('expected', 'got');
}
