#!/usr/bin/perl -w

use EW::Debug;
use EW::Sys;
use EW::Time;
EW::Time::p('tz' => 'UTC');

my $targ = $ARGV[0];
die "need a target time" unless $targ;

# my $ct = 1291174002;
# my $ct = 1291777173;
# my $ct = 1292090693;
# my $ct = 20101211;
my $t = EW::Time->new($targ);
my $ct = $t->tostring("%Y%m%d");
my $ctlong = $t->tostring("%Y-%m-%d %H:%M:%S");
my $epoch = $t->epoch;

my $mythdir = '/ds2/home/eric/dev/mythtv/src/git';
my $ewmgoe = '/ds2/home/eric/dev/git/ew-mythtv-gentoo';

dbg("time: $ct/$epoch/$t", DBGVERBOSE);

my $gitloglevel = DBGVERBOSE;

my %branches = ('master' => { 'ver' => '99999', 'dbv' => 1, 'arch' => '~'}
                , 'fixes/0.24' => { 'ver' => '0.24', 'dbv' => 0, 'arch' => ''}
               );

my %packages = ('0' => { 'pkg' => 'mythtv'
                         , 'mythdir' => "$mythdir/mythtv"
                         , 'ewmgoe' => "$ewmgoe/media-tv/mythtv"
                         , 'inherits' => 'flag-o-matic multilib eutils qt4 toolchain-funcs python versionator' }

                , '1' => { 'pkg' => 'mythplugins'
                           , 'mythdir' => "$mythdir/mythtv"
                           , 'ewmgoe' => "$ewmgoe/media-plugins/mythplugins"
                           , 'inherits' => 'flag-o-matic multilib eutils qt4 toolchain-funcs python versionator' }

                , '2' => { 'pkg' => 'mythweb'
                           , 'mythdir' => "$mythdir/mythweb"
                           , 'ewmgoe' => "$ewmgoe/www-apps/mythweb"
                           , 'inherits' => 'webapp depend.php versionator' }

                , '3' => { 'pkg' => 'myththemes'
                           , 'mythdir' => "$mythdir/myththemes"
                           , 'ewmgoe' => "$ewmgoe/x11-themes/myththemes"
                           , 'inherits' => 'qt4 versionator' }
               );

foreach my $br (keys %branches) {
  my $bb = $branches{$br};
  my $schemaver = '';
  foreach my $j (sort { $a <=> $b } keys %packages) {
    my $p = $packages{$j};

    # select build repo with chdir
    chdir($p->{'mythdir'});
    dbg("Entering: $p->{'mythdir'}", DBGVERBOSE);
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

    # chdir to our ebuild directory for this package
    chdir($p->{'ewmgoe'});
    dbg("Entering: $p->{'ewmgoe'}");

    # construct ebuild filename
    my $fname = "$p->{'ewmgoe'}/$p->{'pkg'}-$bb->{'ver'}"
      . ($bb->{'dbv'} ? ${schemaver} : '')
        . ".$ct.ebuild";

    # create ebuild if not exist
    my $created = 0;
    if (! -e $fname) {

      # but only if no older ebuild exists with same hash
      my $glob = "$p->{'pkg'}-$bb->{'ver'}"
        . ($bb->{'dbv'} ? '.*' : '')
          . ".*.ebuild";
      my @oldebuilds = glob($glob);
      my @matchers = grep(/$hash/, @oldebuilds);
      if (scalar(@matchers) > 0) {

        dbg("Hash hasn't changed from: " . join(', ', @matchers));

      } else {

        my $lines = ebuildcontent($p->{'pkg'}, $br, $ct, $hash, $bb->{'arch'}, $p->{'inherits'});
        EW::File::writelines($fname, $lines);
        dbg("Wrote: $fname");
        $created = 1;

      }
    } else {
      dbg("Exists: $fname");
    }

    # update manifest if not exist or too old
    my $mfest = $p->{'ewmgoe'} . "/Manifest";
    my $mtm = EW::File::mtime($mfest);
    my $mtf = EW::File::mtime($fname);
    if (! -e $mfest || $mtm < $mtf) {
      my ($pi, $pe) = EW::Sys::do("ebuild $fname digest");
      dbg("Manifest updated.");
    } else {
      dbg("Manifest ok.", DBGVERBOSE);
    }

    # test new ebuild for good fetch
    if ($created) {
      EW::Sys::do("sudo ebuild $fname clean", $gitloglevel, $gitloglevel);
      my ($ro, $re) = EW::Sys::do("sudo ebuild $fname prepare", $gitloglevel, $gitloglevel);
      EW::Sys::do("sudo ebuild $fname clean", $gitloglevel, $gitloglevel);
      if (grep(/Source prepared./, @$ro)) {
        dbg("Good prepare cycle.");
      } else {
        dbg("WARNING: PREPARE FAILED: $fname\n +++ "
            . join("\n +++ ", grep(/\bdie\b/, @$ro))
            , DBGWARN);
      }
    }
  }
}

sub ebuildcontent {
  my ($pkg, $branch, $stamp, $hash, $arch, $inherits) = @_;
  $branch = (split('/', $branch))[0];
  my @lines = ('##########################################'
               , '# EW MythTV Gentoo Overlay Ebuilds       #'
               , '# github.com/ewestbrook/ew-mythtv-gentoo #'
               , '# E. Westbrook <ewmgoe@westbrook.com>    #'
               , '##########################################'
               , ''
               , 'EAPI=2'
               , "inherit $inherits"
               , ''
               , "MYTHBRANCH=\"$branch\""
               , "GITHASH=\"$hash\""
               , "inherit ${pkg}-1"
               , ''
               , 'HOMEPAGE="http://www.mythtv.org"'
               , 'LICENSE="GPL-2"'
               , 'RESTRICT="nomirror strip"'
               , 'DESCRIPTION="Homebrew PVR project"'
               , "KEYWORDS=\"${arch}amd64 ${arch}ppc ${arch}x86\""
              );
  push @lines, 'SLOT="0"' unless 'mythweb' eq $pkg;
  return \@lines;
}
