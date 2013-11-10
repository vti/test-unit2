package Test::Unit2::Runner;

use strict;
use warnings;

use File::Find ();
use Test::Unit2::Output::Default;

sub new {
    my $class = shift;
    my (%params) = @_;

    my $self = {};
    bless $self, $class;

    $self->{output} = $params{output} || Test::Unit2::Output::Default->new;
    $self->{loader} = $params{loader} || sub { /Test\.pm$/ };

    return $self;
}

sub run {
    my $self = shift;
    my (@directories) = @_;

    push @directories, '.' unless @directories;

    my @test_files;
    File::Find::find(
        sub {
            local $_ = $File::Find::name;
            push @test_files, $File::Find::name
              if $self->{loader}->($File::Find::name);
        },
        @directories
    );

    my $output = $self->{output};

    $output->start;

    foreach my $test_file (@test_files) {
        my $package = do { open my $fh, '<', $test_file; <$fh> };
        ($package) = $package =~ m/^\s*package\s+(.*?)\s*;/;

        if (!$package->can('new')) {
            eval { require $test_file; 1 } or die $@;
        }

        my $test_case = $package->new;

        $output->watch($test_case);

        $test_case->execute;
    }

    $output->finalize;

    return $self;
}

1;
