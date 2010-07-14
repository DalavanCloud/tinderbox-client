#!/usr/bin/perl -w

use strict;
use lib '.';
require 5.0006;
use Getopt::Long;
use Tinderbox::Client;

GetOptions("upgrade" => \my $do_upgrade) || die $@;

my ($branch, $db) = @ARGV;
my $lcdb = lc($db);
my $branch_no_dots = $branch;
$branch_no_dots =~ s/\.//g;

my $dir = "/var/www/html/bugzilla-qa-$branch";
if ($lcdb ne 'mysql') {
    $dir .= "-$lcdb";
}

my $install_switch = $do_upgrade ? '--upgrade-all' : '--all';

my $client = new Tinderbox::Client({
    Lock      => '.qa-lock',
    Admin     => 'mkanat@bugzilla.org',
    To        => 'tinderbox-daemon@tinderbox.mozilla.org',
    Sleep     => 900,
    Tinderbox => "Bugzilla$branch",
    Build     => "QA $db",
    Commands  => ["bzr up -q selenium",
                  "$^X install-module.pl $install_switch 2> /dev/null",
                  "${lcdb}drop bugs_qa_$branch_no_dots",
                  "$^X checksetup.pl ~/qa-answers", 
                  "cd selenium/config;$^X generate_test_data.pl",
                  "cd selenium/t;prove -v *.t"],
    Dir       => $dir,
    'Failure Strings' => ['[checkout aborted]', 'bzr: ERROR',
                          ': cannot find module', '^C ',
                          'DIED', '# Looks like you planned'],
});

$client->run();
