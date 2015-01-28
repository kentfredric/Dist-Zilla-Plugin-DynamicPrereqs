use strict;
use warnings;

use Test::More;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Test::Fatal;
use Path::Tiny;

# %FallbackPrereqs weren't included by MMA until 0.19
use Test::Requires { 'Dist::Zilla::Plugin::MakeMaker::Awesome' => '0.19' };

my $tzil = Builder->from_config(
    { dist_root => 't/does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                [ GatherDir => ],
                [ Prereqs => { 'strict' => '0', 'Test::More' => '0' } ],
                [ 'MakeMaker::Awesome' => ],    # we don't usually use it directly, but this will do
                [ DynamicPrereqs => {
                        -raw => [
                            q|$WriteMakefileArgs{PREREQ_PM}{'Test::More'} = $FallbackPrereqs{'Test::More'} = '0.123'|,
                            q|if eval { require Test::More; 1 };|,
                        ],
                    },
                ],
            ),
            path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
        },
    },
);

$tzil->chrome->logger->set_debug(1);
is(
    exception { $tzil->build },
    undef,
    'build proceeds normally',
) or diag 'got log messages: ', explain $tzil->log_messages;

my $build_dir = path($tzil->tempdir)->child('build');

my $file = $build_dir->child('Makefile.PL');
ok(-e $file, 'Makefile.PL created');

my $makefile = $file->slurp_utf8;
unlike($makefile, qr/[^\S\n]\n/m, 'no trailing whitespace in modified file');

my $version = Dist::Zilla::Plugin::DynamicPrereqs->VERSION || '<self>';
isnt(
    index(
        $makefile,
        <<CONTENT),
# inserted by Dist::Zilla::Plugin::DynamicPrereqs $version
\$WriteMakefileArgs{PREREQ_PM}{'Test::More'} = \$FallbackPrereqs{'Test::More'} = '0.123'
if eval { require Test::More; 1 };

CONTENT
    -1,
    'code inserted into Makefile.PL generated by [MakeMaker::Awesome]',
) or diag "found Makefile.PL content:\n", $makefile;

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
