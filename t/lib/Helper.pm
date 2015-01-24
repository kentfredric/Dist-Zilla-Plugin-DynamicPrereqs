use strict;
use warnings;

use Test::More ();
use Test::Fatal ();
use Path::Tiny ();
use File::pushd ();
use Capture::Tiny ();

sub run_makemaker
{
    my $tzil = shift;

    my $exception;
    my ($stdout, $stderr, @rest) = Capture::Tiny::capture { $exception =
        Test::Fatal::exception {
            my $wd = File::pushd::pushd(Path::Tiny::path($tzil->tempdir)->child('build'));
            $tzil->plugin_named('MakeMaker')->build;
        }
    };
    Test::More::note $stdout;
    Test::More::is($exception, undef, 'generated Makefile.PL has no compiler errors')
        or diag $stderr;
    Test::More::is($stderr, '', 'running Makefile.PL did not produce warnings');
}

1;
