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
      my ($lines, $pe) = EW::Sys::do("git log --pretty=\"format:$repo,$branch,\%ct,\%H\""
                                     , $gitloglevel
                                     , $gitloglevel);
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
        my ($id, $dbtag, $dbseq, $rootseq) = @{$db->getrow(qq{
          select gs1.id, gs1.tag, gs1.seq, gs1.rootseq
          from gitscan gs1
          where gs1.pkg = ?
          and gs1.branch = ?
          and gs1.hash = ?
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
      $progress->update($max) if $nextupdate < $max;
    }
  }
}

dbg("Updating null seq values.");
my %counts = ();
my $count = 0;
my $nextupdate = 0;
my $max = $db->getval('select count(id) from gitscan');
my $progress = Term::ProgressBar->new ({ 'name'  => "SeqScan"
                                         , 'count' => $max
                                         , 'ETA'   => 'linear' });
my $sth = $db->qstart(qq{
  select id, pkg, branch, tag, seq, rootseq, hash
  from gitscan
  order by epoch
});
while (my $r = $db->qnext($sth)) {
  my $rootseq = $counts{$r->{'pkg'}}{$r->{'branch'}} || 0;
  if (defined $r->{'rootseq'}) {
    if ($r->{'rootseq'} != $rootseq) {
      die "Bad row rootseq $r->{'rootseq'} for calc rootseq $rootseq";
    }
  } else {
    $db->dosql('update gitscan set rootseq = ? where id = ?', $rootseq, $r->{'id'});
  }
  $counts{$r->{'pkg'}}{$r->{'branch'}} = $rootseq + 1;
  $count++;
  $nextupdate = $progress->update($count) if ($count >= $nextupdate);
}
$progress->update($max) if $nextupdate < $max;

dbg("Done.");
