#!/usr/bin/perl -w

use lib '/ds2/home/eric/dev/perl/EW/lib';

use File::Basename;
use EW::DBI;
use EW::Debug;
use EW::Sys;
use EW::Time;
EW::Time::p('tz' => 'UTC');

my $forcewrite = 0;
my $ebuildsonly = 1;
my $gitloglevel = DBGVERBOSE;

my $devdir = '/ds2/home/eric/dev';
my $mythdir = "$devdir/mythtv/src/git";
my $ewmgoe = "$devdir/git/ew-mythtv-gentoo";

my $db = EW::DBI->new('mysql', 'vs01:mythconverg', 'mythtv', 'mythtv') or die "Can't open DB";

my %branches = ('master' => { 'ver' => '99999', 'dbv' => 1, 'arch' => '~'}
                , 'fixes/0.24' => { 'ver' => '', 'dbv' => 0, 'arch' => ''}
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
                           , 'ewmgoe' => "$ewmgoe/www-apps/mythweb"
                           , 'rootseq' => 1 }

                , '3' => { 'pkg' => 'myththemes'
                           , 'pgrep' => 'myththemes'
                           , 'mythdir' => "$mythdir/myththemes"
                           , 'ewmgoe' => "$ewmgoe/x11-themes/myththemes"
                           , 'rootseq' => 1 }

                , '4' => { 'pkg' => 'nuvexport'
                           , 'pgrep' => 'nuvexport'
                           , 'mythdir' => "$mythdir/nuvexport"
                           , 'ewmgoe' => "$ewmgoe/media-video/nuvexport"
                           , 'rootseq' => 1 }

#                 , '5' => { 'pkg' => 'jya-mythtv'
#                            , 'pgrep' => 'jya-mythtv'
#                            , 'mythdir' => "$mythdir/jya-mythtv"
#                            , 'ewmgoe' => "$ewmgoe/media-tv/jya-mythtv" }

#                 , '6' => { 'pkg' => 'jya-mythplugins'
#                            , 'pgrep' => 'jya-mythtv'
#                            , 'mythdir' => "$mythdir/jya-mythtv"
#                            , 'ewmgoe' => "$ewmgoe/media-plugins/jya-mythplugins" }
               );

# iterate packages
PKG: foreach my $j (sort { $a <=> $b } keys %packages) {
  my $p = $packages{$j};
  my $pkg = $p->{'pkg'};
  my $pgrep = $p->{'pgrep'};
  my $pewmgoe = $p->{'ewmgoe'};

  # iterate branches
 BRCH: foreach my $br (keys %branches) {
    my $bb = $branches{$br};
    my $arch = $bb->{'arch'};
    my $bbver = $bb->{'ver'};

    # iterate commits
    my $sth = $db->qstart(qq{
      select id, epoch, tag, seq, hash, rootseq
      from gitscan
      where pkg = ?
      and branch = ?
      order by epoch desc
      limit 10
    }, $pkg, $br);
    while (my $r = $db->qnext($sth)) {
      my ($id, $epoch, $tag, $seq, $hash, $rootseq) = map { $r->{$_} } ('id', 'epoch', 'tag', 'seq', 'hash', 'rootseq');
      $seq = $rootseq if !$seq && $p->{'rootseq'};
      my ($ver, $superminor);
      if ($tag) {
        ($ver, $superminor) = ($tag =~ /.*?(\d+\.\d+(\.\d+)?).*?/);
        $superminor = '.0' unless $superminor;
      }
      if (!$ver) {
        ($ver, $superminor) = ($br =~ /.*?(\d+\.\d+(\.\d+)?).*?/);
        $superminor = '.0' unless $superminor;
      }
      if (!$ver) {
        $ver = '';
        $superminor = '';
      }
      next unless $seq;
      $seq = ".$seq";
      my $b2ver = ($bbver
                   ? ($ver ? "${bbver}.${ver}" : $bbver)
                   : ($ver ? $ver : '99999'));
      writecontent($pewmgoe, $pkg, $br, "${b2ver}${superminor}${seq}", $hash, $arch);
    }
  }
}

dbg("Updating any necessary Manifest files.");
foreach my $i (keys %packages) {
  my $p = $packages{$i};
  mkmanifest($p->{'pkg'}, $p->{'ewmgoe'});
}

dbg("Done.");
exit;

sub writecontent {
  my ($pewmgoe, $pkg, $br, $ver, $hash, $arch) = @_;
  my $bn = "${pkg}-${ver}.ebuild";
  my $f = "$pewmgoe/$bn";
  if (! -e $f) {
    my $lines = ebuildcontent($pkg, $br, $hash, $arch);
    EW::File::writelines($f, $lines);
    dbg("Written: $bn");
  }
}

sub mkmanifest {
  my ($pkg, $pewmgoe) = @_;
  my $mfest = "$pewmgoe/Manifest";
  my $mtm = EW::File::mtime($mfest);
  my @globfiles = (glob("$pewmgoe/*.ebuild"), glob("$pewmgoe/eclass/*.eclass"));
  my $fname = '';
  foreach $i (@globfiles) {
    my $mtf = EW::File::mtime($i);
    if ($mtf && !$mtm || $mtf >= $mtm) {
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

