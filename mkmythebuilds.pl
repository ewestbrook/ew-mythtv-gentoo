#!/usr/bin/perl -w

#
# mkmythebuild.pl
#
# Objective: Scan recent git history for MythTV and related projects,
# collecting the git hash identifiers and relationships to sequence
# numbers in "git describe" Then, create appropriate Gentoo ebuilds
# for the new versions, and rebuild the Gentoo Portage manifests.
#
# Copyright 2010, 2011 Eric E. Westbrook github@westbrook.com
# https://github.com/ewestbrook/ew-mythtv-gentoo
#

use EW::Debug;
EW::Debug::p('level' => DBGINFO);
my $gitloglevel = DBGDEBUG;

use EW::File;
use EW::Sys;
use EW::Time;
use File::Basename;

# initialize time of day settings

EW::Time::p('TZ' => 'UTC');
$ENV{'TZ'} = 'UTC';
my $nowday = EW::Time->now->tostring('%Y%m%d');

# configurable variables

my $maxrevs = 20;
my $homedir = '/home/eric';
my $devdir = "${homedir}/dev";
my $tmpdir = "${homedir}/tmp/ewmgoe";

my $ewmgoehub = 'git@github.com:ewestbrook/ew-mythtv-gentoo.git';
my $ewmgoe = "$tmpdir/ew-mythtv-gentoo";
my $ewmgoeopt = "--git-dir=$ewmgoe/.git --work-tree=$ewmgoe";

# config: associate packages with available repos and branch names

%pkgs = ();
$pkgs{'mythtv'} = { 'cat' => 'media-tv'
                    , 'repo' => 'mythtv'
                    , 'branches' => [ 'fixes/0.24', 'master' ] };
$pkgs{'mythplugins'} = { 'cat' => 'media-plugins'
                    , 'repo' => 'mythtv'
                    , 'branches' => [ 'fixes/0.24', 'master' ] };
$pkgs{'mythweb'} = { 'cat' => 'www-apps'
                     , 'repo' => 'mythweb'
                     , 'branches' => [ 'fixes/0.24', 'master' ] };
$pkgs{'myththemes'} = { 'cat' => 'x11-themes'
                        , 'repo' => 'myththemes'
                        , 'branches' => [ 'fixes/0.24', 'master' ] };
$pkgs{'nuvexport'} = { 'cat' => 'media-video'
                       , 'repo' => 'nuvexport'
                       , 'branches' => [ 'fixes/0.24', 'master' ] };

# config: define repos and their canonical locations

my %repos;
if (1) {
  %repos = ('mythtv' => { 'github' => 'http://github.com/MythTV/mythtv.git', 'cwd' => 'mythtv' }
            , 'mythweb' => { 'github' => 'http://github.com/MythTV/mythweb.git', 'cwd' => 'mythweb' }
            , 'myththemes' => { 'github' => 'http://github.com/MythTV/myththemes.git', 'cwd' => 'myththemes' }
            , 'nuvexport' => { 'github' => 'http://github.com/MythTV/nuvexport.git', 'cwd' => 'nuvexport' });
} else {
  %repos = ('mythtv' => { 'github' => '/home/eric/tmp/refgoe/mythtv', 'cwd' => 'mythtv' }
            , 'mythweb' => { 'github' => '/home/eric/tmp/refgoe/mythweb', 'cwd' => 'mythweb' }
            , 'myththemes' => { 'github' => '/home/eric/tmp/refgoe/myththemes', 'cwd' => 'myththemes' }
            , 'nuvexport' => { 'github' => '/home/eric/tmp/refgoe/nuvexport', 'cwd' => 'nuvexport' });
}

# config: Some specific hashes are not tagged upstream, but do
# correspond to a specific version release.

my %hackytags = ('myththemes' => { 'v0.23' => '3c126bc3c97a547c2de3'
                                   , 'v0.24' => 'f0172278cd378a3c7178'
                                   , 'v0.25pre' => '7491bf1b0d0bb8c8d070' }
                 , 'mythweb' => { 'v0.23' => '6cb91dfea140542a28c7'
                                  , 'v0.24' => 'ee4ac675568969eb69d2'
                                  , 'v0.25pre' => '5a4362e2f1c731fa2418' }
                 , 'nuvexport' => { 'v0.23' => 'dc4f65842c892b292f1d'
                                   , 'v0.24' => '03a753d74908b6bdb7ae'
                                   , 'v0.25pre' => '523aef09357f4a8a4ccc' } );

my @resultfiles = ();
my ($so, $se);

# purge the temporary directory we'll be working in, to start fresh

dbg("Purging $tmpdir", DBGVERBOSE);
($so, $se) = EW::Sys::do("rm -rf $tmpdir");
($so, $se) = EW::Sys::do("mkdir -p $tmpdir");

# create a working clone of the result repository

dbg("Cloning ewmgoe into $ewmgoe", DBGVERBOSE);
($so, $se) = EW::Sys::do("git clone $ewmgoehub $ewmgoe");

# iterate packages

foreach my $pkg (keys %pkgs) {
  my ($cat, $repo) = map { $pkgs{$pkg}{$_} } ('cat', 'repo');
  dbg("Iterating: $pkg", DBGVERBOSE);

  my $wkdir = "$tmpdir/$repo";
  my $wkdiropt = "--git-dir=$wkdir/.git --work-tree=$wkdir";

  # clone this package's repo if we haven't already

  if (!$repos{$repo}{'cloned'}) {
    dbg("Cloning: $repo into $wkdir", DBGVERBOSE);
    ($so, $se) = EW::Sys::do("git clone $repos{$repo}{'github'} $wkdir", $gitloglevel, $gitloglevel, $gitloglevel);
    $repos{$repo}{'cloned'}++;

    # hack in the missing tags!
    my $r = $hackytags{$pkg};
    foreach my $k (keys %$r) {
      ($so, $se) = EW::Sys::do("git $wkdiropt tag $k $r->{$k}"
                               # , DBGINFO, DBGINFO, DBGINFO);
                               , $gitloglevel, $gitloglevel, $gitloglevel);
    }
  }

  # now, iterate this package's branches for new commits to assimilate

  my $branches = $pkgs{$pkg}{'branches'};
  foreach my $br (@$branches) {
    dbg("Iterating: $pkg/$br", DBGVERBOSE);

    dbg("Checkout: $repo/$br", DBGVERBOSE);
    ($so, $se) = EW::Sys::do("git $wkdiropt checkout $br", $gitloglevel, $gitloglevel, $gitloglevel);

    # collect history of commits for this package/branch, in long hash format

    dbg("Scraping full log: $repo/$br", DBGVERBOSE);
    my ($allhashes, $se1) = EW::Sys::do("git $wkdiropt log --reverse --pretty=\"format:%H\"", $gitloglevel, $gitloglevel, $gitloglevel);
    my $i = 0; my %baserevs = map { $_ => $i++ } @$allhashes;

    if (0) {
      dbg("Indexing full log: $repo/$br", DBGVERBOSE);
      my %hashems = ();
      my ($hashtimes, $se2) = EW::Sys::do("git $wkdiropt log --reverse --pretty=\"format:%H %ci\"", $gitloglevel, $gitloglevel, $gitloglevel);
      foreach my $a (@$hashtimes) {
        my ($h, $ci) = ($a =~ /^(\S+)\s(.*)$/);
        $hashems{$h}{'ci'} = $ci;
        $hashems{$h}{'dt'} = EW::Time->new($ci);
        $hashems{$h}{'desc'} = getdesc($h, $wkdiropt);
        my $bvstuff = getbv($hashems{$h}{'desc'});
        foreach my $k (keys %$bvstuff) { $hashems{$h}{$k} = $bvstuff->{$k}; }
      }
    }

    # collect the "git describe" name for each commit

    dbg("Scraping recent log: $repo/$br", DBGVERBOSE);
    my ($hashes, $se) = EW::Sys::do("git $wkdiropt log -n$maxrevs --pretty=\"format:%H\"", $gitloglevel, $gitloglevel, $gitloglevel);

    dbg("Describing recent commits: $repo/$br", DBGVERBOSE);
    my %revs = ();
    foreach my $h (@$hashes) {
      my $d = getdesc($h, $wkdiropt);
      my $bvstuff = getbv($d);
      if ($bvstuff->{'bv'}) {
        foreach my $k (keys %$bvstuff) { $revs{$h}{$k} = $bvstuff->{$k}; }
      } elsif ('master' eq $br) {
        my $seq = $baserevs{$h};
        $revs{$h}{'bv'} = "99999_pre${seq}";
        $revs{$h}{'arch'} = "~";
      }
    }

    # iterate all commits, construct relevant ebuild particulars, and
    # decide whether a new ebuild should be written for that commit

    REV: foreach my $h (@$hashes) {
      next unless defined $revs{$h};
      my $bv = $revs{$h}{'bv'};
      my $arch = $revs{$h}{'arch'};
      my $bn = "${pkg}-${bv}";
      my $d = "${ewmgoe}/${cat}/${pkg}";
      my $f = "${d}/${bn}.ebuild";
      my $w = 'Writing';
      if (-e $f) {
        my $lines = EW::File::readlines($f);
        my ($hashline) = grep(/MYTHCOMMIT/, @$lines);
        my ($fh) = ($hashline =~ /\"(.*)\"/);
        if ($fh eq $h) {
          next REV;
        }
        my $hi = $baserevs{$h};
        my $fhi = $baserevs{$fh};
        if ($hi > $fhi) {
          $w = 'Updating';
        } else {
          dbg("Collides: $bn (${hi}-${h}) < ${fhi}-${fh}", DBGWARN);
          next REV;
        }
      }
      my @globbers = glob("${ewmgoe}/${cat}/${pkg}/*.ebuild");
      foreach my $fq (@globbers) {
        next if $fq eq $f;
        my $lines = EW::File::readlines($fq);
        my ($hashline) = grep(/$h/, @$lines);
        if ($hashline) {
          dbg("Ebuild for $bn duplicates " . basename($fq), DBGWARN);
        }
      }
      dbg("${w} ${h}: ${bn}", DBGINFO);
      my $lines = ebuildcontent($pkg, $br, $h, $arch);
      EW::File::writelines($f, $lines);
      push @resultfiles, $f;
    }
  }
}

# rebuild the portage manifest for each package

foreach my $pkg (keys %pkgs) {
  my $d = "$ewmgoe/$pkgs{$pkg}{'cat'}/${pkg}";
  if (mkmanifest($pkg, $d)) {
    push @resultfiles, "${d}/Manifest";
  }
}

# commit the results back to origin

if (1 && scalar(@resultfiles)) {
  my $gll = $gitloglevel;
  dbg("Commiting for $nowday: " . scalar(@resultfiles) . " files", DBGINFO);
  ($so, $se) = EW::Sys::do('git $ewmgoeopt add ' . join(' ', @resultfiles), $gll, $gll, $gll);
  die "Git add error: \n" . join("\n", @$so, @$se) if scalar(@$se);
  ($so, $se) = EW::Sys::do("git $ewmgoeopt commit -m 'upstream $nowday'", $gll, $gll, $gll);
  ($so, $se) = EW::Sys::do('git $ewmgoeopt push', $gll, $gll, $gll);
}

# done

exit;

# mkmanifest($pkg, $pewmgoe)
# Helper function to rebuild one portage manifest

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
  return 0 unless $fname;
  dbg("Updating Manifest: $pkg", DBGINFO);
  chdir($pewmgoe);
  my ($pi, $pe) = EW::Sys::do("ebuild $fname digest", $gitloglevel, $gitloglevel, $gitloglevel);
  return 1;
}

# ebuildcontent($pkg, $branch, $hash, $arch)
#
# Generates a single ebuild file representing a package and commit,
# from which the package can be installed to that version using
# portage's emerge command.

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

# getdesc($h, $wkdiropt)
# Retrieve the "git describe" tag for a given commit

sub getdesc {
  my ($h, $wkdiropt) = @_;
  ($so, $se) = EW::Sys::do("git $wkdiropt describe --tags $h", $gitloglevel, $gitloglevel, $gitloglevel);
  my $d = shift @$so;
  $d = '' unless defined $d;
  return $d;
}

# getbv($d)
# Extract portage-compatible particulars from a "git describe" tag.

sub getbv {
  my $d = shift;
  my ($bv, $arch, $vn, $vntype, $seq) = ('', '', '', '', '');
  if (($vn, $vntype, undef, $seq) = ($d =~ /^[^\d\.]*?([\d\.]+)(pre|)(-([^-]+)-[^-]+)?$/)) {
    $seq = 0 unless $seq;
    $bv = "${vn}" . ('pre' eq $vntype ? "_pre${seq}" : ($seq ? "_p${seq}" : ''));
    $arch = ('pre' eq $vntype ? '~' : '');
  }
  my %lhs = ('vn' => $vn
             , 'vntype' => $vntype
             , 'seq' => $seq
             , 'bv' => $bv
             , 'arch' => $arch);
  return \%lhs;
}
