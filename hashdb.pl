#!/usr/bin/perl -w

use lib '/ds2/home/eric/dev/perl/EW/lib';

use EW::DBI;
use EW::Debug;
use EW::File;
use EW::Sys;
use EW::Time;
use File::Copy ('cp', 'mv');
use Term::ProgressBar;

EW::Time::p('TZ' => 'UTC');
$ENV{'TZ'} = 'UTC';

my $gitloglevel = DBGVERBOSE;

my $devdir = '/ds2/home/eric/dev';
my $mythdir = "$devdir/mythtv/src/git";
my $ewmgoe = "$devdir/git/ew-mythtv-gentoo";
my $dbfile = "$ewmgoe/hashdb.txt";

my $repos = { 'mythtv' => { 'cat' => 'media-tv', 'pkgs' => ['mythtv', 'mythplugins'] }
              , 'mythweb' => { 'cat' => 'www-apps', 'pkgs' => ['mythweb'] }
              , 'myththemes' => { 'cat' => 'x11-themes', 'pkgs' => ['myththemes'] }
              , 'nuvexport' => { 'cat' => 'media-video', 'pkgs' => ['nuvexport'] }
              # ,  'jya-mythtv' => { 'cat' => 'media-tv', 'pkgs' => ['jya-mythtv', 'jya-mythplugins'] }
            };

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
    EW::Sys::do("git checkout $branch", $gitloglevel, $gitloglevel);
    dbg("Pulling $repo:$branch");
    EW::Sys::do('git pull', $gitloglevel, $gitloglevel);

    foreach my $pkg (@{$repos->{$repo}{'pkgs'}}) {

      # dump
      dbg("Dumping $pkg:$branch");
      my ($lines, $pe) = EW::Sys::do("git log --pretty=\"format:$repo,$branch,\%ct,\%H\"", $gitloglevel, $gitloglevel);
      if (scalar(@$pe)) {
        dbg("Error dumping: $pkg:$branch");
        next;
      }

      # insert
      dbg("Considering inserts for $pkg:$branch");
      my $count = 0;
      my $nextupdate = 0;
      my $max = scalar(@$lines);
      my $progress = Term::ProgressBar->new ({ 'name'  => "${pkg}-${branch}"
                                               , 'count' => $max
                                               , 'ETA'   => 'linear' });
      $progress->max_update_rate(1);
      $progress->minor(0);
      foreach my $line (@$lines) {
        my (undef, undef, $t, $h) = split(',', $line);
        my ($id, $dbtag, $dbseq) = @{$db->getrow(qq{
          select id,tag,seq from gitscan
          where pkg = ?
          and branch = ?
          and hash = ?
        }, $pkg, $branch, $h)};
        if (!$id) {
          my ($do, $de) = EW::Sys::do("git describe $h", $gitloglevel, $gitloglevel);
          my ($tag, $seq, $ish);
          if (scalar(@$do)) {
            my $descline = $do->[0];
            ($tag, $seq, $ish) = split('-', $descline);
            die "hash $h doesn't begin with ish $ish" unless !$ish || "g$h" =~ /^$ish/;
          }
          my $dbsv = ('mythtv' eq $pkg ? $schemavers{$branch}{$t} : undef);
          my $ptag = $tag || '';
          my $pseq = $seq || '';
          dbg("Inserting: $pkg:$branch:$t:$h:$ptag:$pseq");
          $db->dosql(qq{
            replace into gitscan set
              pkg = ?
              , branch = ?
              , epoch = ?
              , hash = ?
              , dbschemaver = ?
              , tag = ?
              , seq = ?
            }, $pkg, $branch, $t, $h, $dbsv, $tag, $seq);
        }
        $count++;
        $nextupdate = $progress->update($count) if ($count >= $nextupdate);
      }
      dbg("count = $count, cnextupdate = $nextupdate, max = $max");
      $progress->update($max) if $nextupdate < $max;
    }
  }
}
