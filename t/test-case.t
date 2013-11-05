use strict;
use warnings;

use Test::More;
use Storable qw(dclone);

use Test::Unit2::TestCase;

subtest 'success notify before/after test_case' => sub {
    my @before;
    my @after;

    my $case = TestCaseSuccess->new;
    $case->bind(
        'before:test_case' => sub {
            push @before, map { dclone($_) } @_;
        }
    );
    $case->bind(
        'after:test_case' => sub {
            push @after, map { dclone($_) } @_;
        }
    );
    $case->execute;

    is_deeply(\@before, [{test_case => 'TestCaseSuccess'}]);
    is_deeply(
        \@after,
        [
            {
                test_case => 'TestCaseSuccess',
                ok        => 1,
                methods   => [{test_method => 'test_hi', ok => 1}]
            }
        ]
    );
};

subtest 'success notify before/after test_method' => sub {
    my @before;
    my @after;

    my $case = TestCaseSuccess->new;
    $case->bind(
        'before:test_method' => sub {
            push @before, map { dclone($_) } @_;
        }
    );
    $case->bind(
        'after:test_method' => sub {
            push @after, map { dclone($_) } @_;
        }
    );
    $case->execute;

    is_deeply(
        \@before,
        [
            {
                test_case => 'TestCaseSuccess',
                methods   => [{test_method => 'test_hi'}]
            }
        ]
    );
    is_deeply(
        \@after,
        [
            {
                test_case => 'TestCaseSuccess',
                ok        => 1,
                methods   => [{test_method => 'test_hi', ok => 1}]
            }
        ]
    );
};

subtest 'failure notify before/after test_case' => sub {
    my @before;
    my @after;

    my $case = TestCaseFailure->new;
    $case->bind(
        'before:test_case' => sub {
            push @before, map { dclone($_) } @_;
        }
    );
    $case->bind(
        'after:test_case' => sub {
            push @after, map { dclone($_) } @_;
        }
    );
    $case->execute;

    is_deeply(\@before, [{test_case => 'TestCaseFailure'}]);
    is_deeply(
        \@after,
        [
            {
                test_case => 'TestCaseFailure',
                ok        => 0,
                methods   => [{test_method => 'test_hi', ok => 0}]
            }
        ]
    );
};

subtest 'failure notify before/after test_method' => sub {
    my @before;
    my @after;

    my $case = TestCaseFailure->new;
    $case->bind(
        'before:test_method' => sub {
            push @before, map { dclone($_) } @_;
        }
    );
    $case->bind(
        'after:test_method' => sub {
            push @after, map { dclone($_) } @_;
        }
    );
    $case->execute;

    is_deeply(
        \@before,
        [
            {
                test_case => 'TestCaseFailure',
                methods   => [{test_method => 'test_hi'}]
            }
        ]
    );
    is_deeply(
        \@after,
        [
            {
                test_case => 'TestCaseFailure',
                ok        => 0,
                methods   => [{test_method => 'test_hi', ok => 0}]
            }
        ]
    );
};

subtest 'error notify before/after test_case' => sub {
    my @before;
    my @after;

    my $case = TestCaseError->new;
    $case->bind(
        'before:test_case' => sub {
            push @before, map { dclone($_) } @_;
        }
    );
    $case->bind(
        'after:test_case' => sub {
            push @after, map { dclone($_) } @_;
        }
    );
    $case->execute;

    is_deeply(\@before, [{test_case => 'TestCaseError'}]);
    like(delete $after[0]->{methods}->[0]->{error}, qr/here/);
    is_deeply(
        \@after,
        [
            {
                test_case => 'TestCaseError',
                ok        => 0,
                methods   => [
                    {
                        test_method => 'test_hi',
                        ok          => 0,
                    }
                ]
            }
        ]
    );
};

subtest 'error notify before/after test_method' => sub {
    my @before;
    my @after;

    my $case = TestCaseError->new;
    $case->bind(
        'before:test_method' => sub {
            push @before, map { dclone($_) } @_;
        }
    );
    $case->bind(
        'after:test_method' => sub {
            push @after, map { dclone($_) } @_;
        }
    );
    $case->execute;

    is_deeply(
        \@before,
        [
            {
                test_case => 'TestCaseError',
                methods   => [{test_method => 'test_hi'}]
            }
        ]
    );
    like(delete $after[0]->{methods}->[0]->{error}, qr/here/);
    is_deeply(
        \@after,
        [
            {
                test_case => 'TestCaseError',
                ok        => 0,
                methods   => [
                    {
                        test_method => 'test_hi',
                        ok          => 0,
                    }
                ]
            }
        ]
    );
};

subtest 'fail if one test fails' => sub {
    my @before;
    my @after;

    {
        package TestCaseOneFails;
        use base 'Test::Unit2::TestCase';

        sub test_ok     { shift->assert(1) }
        sub test_not_ok { shift->assert(0) }
        sub test_z_ok   { shift->assert(1) }
    }

    my $case = TestCaseOneFails->new;
    $case->bind(
        'before:test_case' => sub {
            push @before, map { dclone($_) } @_;
        }
    );
    $case->bind(
        'after:test_case' => sub {
            push @after, map { dclone($_) } @_;
        }
    );
    $case->execute;

    is_deeply(
        \@before,
        [
            {
                test_case => 'TestCaseOneFails',
            }
        ]
    );
    is_deeply(
        \@after,
        [
            {
                test_case => 'TestCaseOneFails',
                ok        => 0,
                methods   => [
                    {test_method => 'test_not_ok', ok => 0},
                    {test_method => 'test_ok',     ok => 1},
                    {test_method => 'test_z_ok',   ok => 1}
                ]
            }
        ]
    );
};

subtest 'stop on first failed assert' => sub {
    my @before;
    my @after;

    {
        package TestCaseStop;
        use base 'Test::Unit2::TestCase';

        sub test_me     {
            my $self = shift;

            $self->assert(1);
            $self->assert(0);
            $self->assert(1);
        }
    }

    my $case = TestCaseStop->new;
    $case->bind(
        'before:test_case' => sub {
            push @before, map { dclone($_) } @_;
        }
    );
    $case->bind(
        'after:test_case' => sub {
            push @after, map { dclone($_) } @_;
        }
    );
    $case->execute;

    is_deeply(
        \@before,
        [
            {
                test_case => 'TestCaseStop',
            }
        ]
    );
    is_deeply(
        \@after,
        [
            {
                test_case => 'TestCaseStop',
                ok        => 0,
                methods   => [
                    {test_method => 'test_me', ok => 0},
                ]
            }
        ]
    );
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

subtest 'run inherited test methods' => sub {
    my @RUN;

    {

        package TestCaseParent;
        use base 'Test::Unit2::TestCase';

        sub new {
            my $self = shift->SUPER::new(@_);
            my (%params) = @_;

            $self->{run} = $params{run};

            return $self;
        }

        sub test_child {
            my $self = shift;
            push @{$self->{run}}, 'test_child_old';
        }

        sub test_parent {
            my $self = shift;
            push @{$self->{run}}, 'test_parent';
        }
    }

    {

        package TestCaseChild;
        use base 'TestCaseParent';

        sub test_child {
            my $self = shift;
            push @{$self->{run}}, 'test_child';
        }
    }

    my $case = TestCaseChild->new(run => \@RUN);
    $case->execute;

    is_deeply(\@RUN, ['test_child', 'test_parent']);
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

package TestCaseError;
use base 'Test::Unit2::TestCase';

sub test_hi {
    my $self = shift;

    die 'here';
}
