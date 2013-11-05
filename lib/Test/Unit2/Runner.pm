package Test::Unit2::Runner;

use strict;
use warnings;

use File::Find ();
use Class::Load;

sub new {
    my $class = shift;

    my $self = {};
    bless $self, $class;

    return $self;
}

sub run {
    my $self = shift;
    my (@directories) = @_;

    push @directories, '.' unless @directories;

    my @test_files;
    File::Find::find(
        sub {
            push @test_files, $File::Find::name if /Test\.pm$/;
        },
        @directories
    );

    my @errors;

    my $result       = 1;
    my $test_methods = 0;
    foreach my $test_file (@test_files) {
        eval { require $test_file; 1 } or die $!;
        my $package = do { open my $fh, '<', $test_file; <$fh> };
        ($package) = $package =~ m/^\s*package\s+(.*?)\s*;/;

        my $test_case = $package->new;

        $test_case->bind(
            'before:test_case' => sub {
                my ($title) = @_;

                print "$title....\n";
            }
        );

        $test_case->bind(
            'after:test_case' => sub {
                my ($ok) = @_;

                print "...", ($ok ? "PASS" : "FAIL"), "\n";
            }
        );

        $test_case->bind(
            'before:test_method' => sub {
                my ($title) = @_;

                print "    $title...";
            }
        );

        $test_case->bind(
            'after:test_method' => sub {
                my (%result) = @_;

                print $result{ok} ? "OK" : $result{error} ? 'ERROR' : "FAIL",
                  "\n";

                if (my $error = $result{error}) {
                    print "$error";

                    push @errors,
                      {
                        test_class  => '',
                        test_method => '',
                        message     => $error
                      }
                }

                $test_methods++;
                $result = 0 unless $result{ok};
            }
        );

        $test_case->execute;
    }

    my $files = @test_files;

    print "Files=$files, Tests=$test_methods, \n";
    print "Result: ", ($result ? "PASS" : "FAIL"), "\n";

    if (@errors) {
        print "\n";
        print "Errors:\n";

        my $counter = 1;
        foreach my $error (@errors) {
            print "$counter) $error->{test_class}\n";
            print "$error->{message}\n\n";

            $counter++;
        }
    }

    return $self;
}

1;
