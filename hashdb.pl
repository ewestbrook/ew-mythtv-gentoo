#!/usr/bin/perl -w

use lib '/home/eric/dev/perl/EW/lib';

use EW::DBI;
use EW::Debug;
use EW::File;
use EW::Sys;
use EW::Time;
use File::Copy ('cp', 'mv');

EW::Time::p('TZ' => 'UTC');
$ENV{'TZ'} = 'UTC';

my $gitloglevel = DBGVERBOSE;

my $devdir = '/ds2/home/eric/dev';
my $mythdir = "$devdir/mythtv/src/git";
my $ewmgoe = "$devdir/git/ew-mythtv-gentoo";
my $dbfile = "$ewmgoe/hashdb.txt";

my $pkgs = { 'mythtv' => { 'repo' => 'mythtv' }
             , 'mythplugins' => { 'repo' => 'mythtv' }
             , 'mythweb' => { 'repo' => 'mythweb' }
             , 'myththemes' => { 'repo' => 'myththemes' }
             , 'nuvexport' => { 'repo' => 'nuvexport' } };

my $repos = { 'mythtv' => { 'cat' => 'media-tv', 'pkgs' => ['mythtv', 'mythplugins'] }
              , 'mythweb' => { 'cat' => 'www-apps', 'pkgs' => ['mythweb'] }
              , 'myththemes' => { 'cat' => 'x11-themes', 'pkgs' => ['myththemes'] }
              , 'nuvexport' => { 'cat' => 'media-video', 'pkgs' => ['nuvexport'] } };

my $branches = { 'master' => { }
                 , 'fixes/0.24' => { } };

my %schemavers = ('master' => { 1282172207 => 1263
                                , 1285701681 => 1264
                                , 1291938306 => 1265 }
                  , 'fixes/0.24' => { 1287469311 => 1264 } );

my $db = EW::DBI->new('mysql', 'vs01:mythconverg', 'mythtv', 'mythtv') or die "Can't open DB";

foreach my $repo (keys %$repos) {

  # scrub
  if (0) {
    dbg("Scrubbing $repo");
    EW::Sys::do("rm -rf $mythdir/$repo");
    dbg("Restoring $repo");
    EW::Sys::do("cp -rp $mythdir/${repo}-clone $mythdir/$repo");
  }

  # fetch
  chdir("$mythdir/$repo");
  dbg("Now in: $mythdir/$repo");
  dbg("Fetching: $repo");
  EW::Sys::do('git fetch');

  # pull
  foreach my $branch (keys %$branches) {
    dbg("Checking out $repo:$branch");
    EW::Sys::do("git checkout $branch");
    dbg("Pulling $repo:$branch");
    EW::Sys::do('git pull');

    foreach my $pkg (@{$repos->{$repo}{'pkgs'}}) {

      # dump
      dbg("Dumping $pkg:$branch");
      my ($lines, $pe) = EW::Sys::do("git log --pretty=\"format:$repo,$branch,\%ct,\%H\"");
      if (scalar(@$pe)) {
        dbg("Error dumping: $pkg:$branch");
        next;
      }

      # insert
      dbg("Inserting log: $pkg:$branch");
      my ($m, $n) = (0, 0);
      foreach my $line (@$lines) {
        $m++;
        my (undef, undef, $t, $h) = split(',', $line);
        my $id = $db->getval(qq{
          select id from gitscan
          where pkg = ?
          and branch = ?
          and hash = ?
        }, $pkg, $branch, $h);
        if (!$id) {
          my $dbsv = ('mythtv' eq $pkg ? $schemavers{$branch}{$t} : undef);
          dbg("Inserting: $h/$t");
          $db->dosql(qq{
            replace into gitscan set
              pkg = ?
              , branch = ?
              , epoch = ?
              , hash = ?
              , dbschemaver = ? }
                     , $pkg, $branch, $t, $h, $dbsv);
          $n++;
        }
      }
      dbg("Inserted for $pkg:$branch: $n records");
    }
  }
}
