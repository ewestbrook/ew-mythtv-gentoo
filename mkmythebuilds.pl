#!/usr/bin/perl -w

use File::Basename;
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

my $mythdir = '/ds2/home/eric/dev/mythtv/src/git';
my $ewmgoe = '/ds2/home/eric/dev/git/ew-mythtv-gentoo';
my $dbfile = "$ewmgoe/hashdb.txt";

my %db = ();
dbread(\%db);

dbg("time: $ct/$epoch/$t", DBGVERBOSE);

my %branches = ('master' => { 'ver' => '99999', 'dbv' => 1, 'arch' => '~'}
                , 'fixes/0.24' => { 'ver' => '0.24.0', 'dbv' => 0, 'arch' => ''}
               );

my %packages = ('0' => { 'pkg' => 'mythtv'
                         , 'mythdir' => "$mythdir/mythtv"
                         , 'ewmgoe' => "$ewmgoe/media-tv/mythtv" }

                , '1' => { 'pkg' => 'mythplugins'
                           , 'mythdir' => "$mythdir/mythtv"
                           , 'ewmgoe' => "$ewmgoe/media-plugins/mythplugins" }

                , '2' => { 'pkg' => 'mythweb'
                           , 'mythdir' => "$mythdir/mythweb"
                           , 'ewmgoe' => "$ewmgoe/www-apps/mythweb" }

                , '3' => { 'pkg' => 'myththemes'
                           , 'mythdir' => "$mythdir/myththemes"
                           , 'ewmgoe' => "$ewmgoe/x11-themes/myththemes" }
               );

foreach my $br (keys %branches) {
  my $bb = $branches{$br};
  my $schemaver = '';
  PKG: foreach my $j (sort { $a <=> $b } keys %packages) {
    my $p = $packages{$j};

    # select build repo with chdir
    chdir($p->{'mythdir'});
    # dbg("Entering: $p->{'mythdir'}", DBGVERBOSE);
    my $hash = '';

    # get hash of desired commit
    foreach my $c ("git co $br"
                   # , 'git fetch'
                   # , 'git pull'
                   , "git log -n1 --pretty=\"format:%H\" --until=\"$ctlong\"") {
      my ($so, $se) = EW::Sys::do($c, $gitloglevel, $gitloglevel);
      $hash = $so->[0];
    }
    die "Can't obtain hash for $p->{'pkg'}/$br/$ct" unless $hash;
    dbg("At $ct: $p->{'pkg'}/$br -> $hash", DBGVERBOSE);

    # see if that hash is used by an ebuild already
    my $glob = "$p->{'ewmgoe'}/*.ebuild";
    my @globfiles = glob($glob);
    foreach my $i (@globfiles) {
      next if $i =~ /$ct/;
      my $lines = EW::File::readlines($i);
      my @lhs = grep(/$hash/, @$lines);
      if (scalar(@lhs)) {
        dbg("Skipping $p->{'pkg'}-$br-$ct: Hash already used in " . basename($i));
        next PKG;
      }
    }

    # get schema version if dbv specified
    EW::Sys::do("git co $hash", $gitloglevel, $gitloglevel);
    my $dbcheckfile = "$p->{'mythdir'}/mythtv/libs/libmythtv/dbcheck.cpp";
    if ((!$schemaver || $bb->{'dbv'}) && -e $dbcheckfile) {
      my $dbcheckcpp = EW::File::readlines($dbcheckfile);
      my $dbvre = qr/^const QString currentDatabaseVersion = \"(\d+)\";$/;
      my @dbverlines = grep(/$dbvre/, @$dbcheckcpp);
      $dbverlines[0] =~ /$dbvre/;
      $schemaver = ".$1";
    }

    # construct ebuild filename
    my $bn = "$p->{'pkg'}-$bb->{'ver'}"
      . ($bb->{'dbv'} ? ${schemaver} : '')
        . ".$ct";
    my $fname = "$p->{'ewmgoe'}/${bn}.ebuild";

    # chdir to our ebuild directory for this package
    chdir($p->{'ewmgoe'});

    # create ebuild if not exist or forced
    my $created = 0;
    if ($forcewrite || ! -e $fname) {

      my $lines = ebuildcontent($p->{'pkg'}, $br, $hash, $bb->{'arch'});
      EW::File::writelines($fname, $lines);
      dbg("Written: $bn");
      $created = 1;

    } else {
      dbg("Exists: $bn");
    }

    # touch up the branch's "bleeding 9s" ebuild if different or forced
    my $bfname = "$p->{'ewmgoe'}/$p->{'pkg'}-$bb->{'ver'}.99999999.ebuild";
    my $oldlines = (-e $bfname ? EW::File::readlines($bfname) : []);
    my $lines = ebuildcontent($p->{'pkg'}, $br, '', '~');
    if ($forcewrite || !EW::Collection::equiv($oldlines, $lines)) {
      EW::File::writelines($bfname, $lines);
      dbg("Written: $bfname");
    }

    # update manifest if not exist or too old
    my $mfest = $p->{'ewmgoe'} . "/Manifest";
    my $mtm = EW::File::mtime($mfest);
    my $mtf = EW::File::mtime($fname);
    my $mtb = EW::File::mtime($bfname);
    if (! -e $mfest || $mtm < $mtf || $mtm < $mtb) {
      if (!$ebuildsonly) {
        my ($pi, $pe) = EW::Sys::do("ebuild $fname digest");
        dbg("Manifest updated.");
      }
    } else {
      dbg("Manifest ok.", DBGVERBOSE);
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

sub dbgrok {
  my ($db, $lines) = @_;
  foreach my $line (@$lines) {
    if (my ($pkg, $br, $ct, $hash) = split(',', $line)) {
      $db->{$pkg}{$br}{'byhash'}{$hash} = $ct;
      $db->{$pkg}{$br}{'bytime'}{$ct} = $hash;
    }
  }
}

sub dbread {
  my $db = shift;
  if (-e $dbfile) {
    my $lines = EW::File::readlines($dbfile);
    dbgrok($db, $lines);
  }
  return $db;
}

