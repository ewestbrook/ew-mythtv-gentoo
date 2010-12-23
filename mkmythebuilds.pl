#!/usr/bin/perl -w

use lib '/home/eric/dev/perl/EW/lib';

use File::Basename;
use EW::DBI;
use EW::Debug;
use EW::Sys;
use EW::Time;
EW::Time::p('tz' => 'UTC');

my $targ = $ARGV[0];
die "need a target time" unless $targ;

my $forcewrite = 0;
my $ebuildsonly = 1;
my $gitloglevel = DBGVERBOSE;

my $t = EW::Time->new($targ);
my $ct = $t->tostring("%Y%m%d.%H%M%S");
my $ctlong = $t->tostring("%Y-%m-%d %H:%M:%S");
my $epoch = $t->epoch;

my $devdir = '/ds2/home/eric/dev';
my $mythdir = "$devdir/mythtv/src/git";
my $ewmgoe = "$devdir/git/ew-mythtv-gentoo";

my $db = EW::DBI->new('mysql', 'vs01:mythconverg', 'mythtv', 'mythtv') or die "Can't open DB";

dbg("time: $ct/$epoch/$t", DBGVERBOSE);

my %branches = ('master' => { 'ver' => '99999', 'dbv' => 1, 'arch' => '~'}
                , 'fixes/0.24' => { 'ver' => '0.24.0', 'dbv' => 0, 'arch' => ''}
               );

my %packages = ('0' => { 'pkg' => 'mythtv'
                         , 'pgrep' => 'mythtv'
                         , 'mythdir' => "$mythdir/mythtv"
                         , 'ewmgoe' => "$ewmgoe/media-tv/mythtv" }

                , '1' => { 'pkg' => 'mythplugins'
                           , 'pgrep' => 'mythtv'
                           , 'mythdir' => "$mythdir/mythtv"
                           , 'ewmgoe' => "$ewmgoe/media-plugins/mythplugins" }

                , '2' => { 'pkg' => 'mythweb'
                           , 'pgrep' => 'mythweb'
                           , 'mythdir' => "$mythdir/mythweb"
                           , 'ewmgoe' => "$ewmgoe/www-apps/mythweb" }

                , '3' => { 'pkg' => 'myththemes'
                           , 'pgrep' => 'myththemes'
                           , 'mythdir' => "$mythdir/myththemes"
                           , 'ewmgoe' => "$ewmgoe/x11-themes/myththemes" }

                , '4' => { 'pkg' => 'nuvexport'
                           , 'pgrep' => 'nuvexport'
                           , 'mythdir' => "$mythdir/nuvexport"
                           , 'ewmgoe' => "$ewmgoe/media-video/nuvexport" }
               );

foreach my $br (keys %branches) {
  my $bb = $branches{$br};
  PKG: foreach my $j (sort { $a <=> $b } keys %packages) {
    my $p = $packages{$j};
    my $pkg = $p->{'pkg'};
    my $pgrep = $p->{'pgrep'};
    my $pewmgoe = $p->{'ewmgoe'};

    # get latest hash to target time
    my ($hashepoch, $hash) = gethash($pkg, $pgrep, $br, $epoch, $pewmgoe);
    next unless $hash;
    my $hashtime = EW::Time->new($hashepoch);
    my $ht = $hashtime->tostring("%Y%m%d.%H%M%S");
    dbg("At $epoch: $pkg/$br -> $hash ($hashepoch/$ht)");

    # get schema version if dbv specified
    my $schemaver = ($p->{'dbv'} ? getschemaver($br, $hashepoch) : '');

    # construct ebuild filename
    my $bn = "$pkg-$bb->{'ver'}"
      . ($bb->{'dbv'} ? ".${schemaver}" : '')
        . ".$ht";
    my $fname = "$p->{'ewmgoe'}/${bn}.ebuild";

    # chdir to our ebuild directory for this package
    chdir($p->{'ewmgoe'});

    # create ebuild if not exist or forced
    my $created = 0;
    if ($forcewrite || ! -e $fname) {
      my $lines = ebuildcontent($pkg, $br, $hash, $bb->{'arch'});
      EW::File::writelines($fname, $lines);
      dbg("Written: ${bn}.ebuild");
      $created = 1;
    } else {
      dbg("Exists: ${bn}.ebuild");
    }

    # touch up the branch's "bleeding 9s" ebuild if different or forced
    my $bfname = "$p->{'ewmgoe'}/$pkg-$bb->{'ver'}.99999999.ebuild";
    my $oldlines = (-e $bfname ? EW::File::readlines($bfname) : []);
    my $lines = ebuildcontent($pkg, $br, '', '~');
    if ($forcewrite || !EW::Collection::equiv($oldlines, $lines)) {
      EW::File::writelines($bfname, $lines);
      dbg("Written: $bfname");
    }

    # test new ebuild for good fetch
    if ($created && !$ebuildsonly) {
      EW::Sys::do("sudo ebuild $fname clean", $gitloglevel, $gitloglevel);
      my ($ro, $re) = EW::Sys::do("sudo ebuild $fname prepare", $gitloglevel, $gitloglevel);
      EW::Sys::do("sudo ebuild $fname clean", $gitloglevel, $gitloglevel);
      if (grep(/Source prepared./, @$ro)) {
        dbg("Good prepare cycle.");
      } else {
        dbg("WARNING: PREPARE FAILED: $bn\n +++ "
            . join("\n +++ ", grep(/\bdie\b/, @$ro))
            , DBGWARN);
      }
    }
  }
}

foreach my $i (keys %packages) {
  my $p = $packages{$i};
  mkmanifest($p->{'pkg'}, $p->{'ewmgoe'});
}

sub gethash {
  my ($pkg, $pgrep, $br, $epoch, $pewmgoe) = @_;
  dbg("Searching for $pkg/$br/$ct", DBGVERBOSE);
  my ($hashepoch, $hash) = @{$db->getrow(qq{
      select epoch, hash
      from gitscan
      where pkg = ?
        and branch = ?
        and epoch <= ?
      order by epoch desc
      limit 1 
    }, $pgrep, ('nuvexport' ne $pkg ? $br : 'master'), $epoch)};
  if (!$hash) {
    dbg("Can't obtain hash for $pkg/$br/$epoch");
    return '';
  }

  # see if that hash is used by an ebuild already
  my $glob = "$pewmgoe/*.ebuild";
  my @globfiles = glob($glob);
  foreach my $i (@globfiles) {
    next if $i =~ /$ct/;
    my $lines = EW::File::readlines($i);
    my @lhs = grep(/$hash/, @$lines);
    if (scalar(@lhs)) {
      dbg("Skipping $pkg-$br-$ct: Hash already used in " . basename($i));
      return '';
    }
  }
  return ($hashepoch, $hash);
}

sub getschemaver {
  my ($br, $hashepoch) = @_;
  $schemaver = $db->getval(qq{
      select max(dbschemaver)
      from gitscan
      where pkg = 'mythtv'
        and branch = ?
        and epoch <= ?
    }, $br, $hashepoch);
  if (!$schemaver) {
    dbg("Can't get schema version for $br at $hashepoch");
    next PKG;
  } else {
    dbg("Schema level on branch $br at $hashepoch: $schemaver");
  }
}

sub mkmanifest {
  my ($pkg, $pewmgoe) = @_;
  my $mfest = "$pewmgoe/Manifest";
  my $mtm = EW::File::mtime($mfest);
  my $glob = "$pewmgoe/*.ebuild";
  my @globfiles = glob($glob);
  my $fname = '';
  foreach $i (@globfiles) {
    my $mtf = EW::File::mtime($i);
    if ($mtf >= $mtm) {
      $fname = $i;
      last;
    }
  }
  return unless $fname;
  chdir($pewmgoe);
  my ($pi, $pe) = EW::Sys::do("ebuild $fname digest");
  dbg("Manifest for $pkg updated.");
}

sub ebuildcontent {
  my ($pkg, $branch, $hash, $arch) = @_;
  $branch = (split('/', $branch))[0];
  my @lines = ('##########################################'
               , '# EW MythTV Gentoo Overlay Ebuilds       #'
               , '# github.com/ewestbrook/ew-mythtv-gentoo #'
               , '# E. Westbrook <ewmgoe@westbrook.com>    #'
               , '##########################################'
               , ''
               , "MYTHBRANCH=\"$branch\""
               , "MYTHCOMMIT=\"$hash\""
               , "KEYWORDS=\"${arch}amd64 ${arch}ppc ${arch}x86\""
               , "inherit ew-${pkg}"
              );
  return \@lines;
}

