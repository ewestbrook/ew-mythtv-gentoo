#!/usr/bin/perl -w

use lib '/home/eric/dev/git/EW/lib';

use EW::Debug;
EW::Debug::p('level' => DBGINFO);

use EW::File;
use EW::Sys;
use EW::Time;
use File::Basename;

EW::Time::p('TZ' => 'UTC');
$ENV{'TZ'} = 'UTC';
my $nowday = EW::Time->now->tostring('%Y%m%d');

dbg("====================", DBGDEBUG);
dbg("===== $0 start =====", DBGDEBUG);
dbg("====================", DBGDEBUG);

my $gitloglevel = DBGDEBUG;

my @resultfiles = ();

my $maxrevs = 10;
my $homedir = '/home/eric';
my $devdir = "${homedir}/dev";
my $tmpdir = "${homedir}/tmp/ewmgoe";

# my $ewmgoehub = 'git@github.com:ewestbrook/ew-mythtv-gentoo.git';
my $ewmgoehub = '/home/eric/dev/git/ew-mythtv-gentoo';
my $ewmgoe = "$tmpdir/ew-mythtv-gentoo";
my $ewmgoeopt = "--git-dir=$ewmgoe/.git --work-tree=$ewmgoe";

my ($so, $se);

%pkgs = ();
$pkgs{'mythtv'} = { 'cat' => 'media-tv'
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
if (0) {
}

my %repos;
if (0) {
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

# my $cat = 'media-tv';
# my $pkg = 'mythtv';
# my $br = 'fixes/0.24';
# my $repo = 'mythtv';
# my $arch = '';

dbg("Purging $tmpdir", DBGVERBOSE);
($so, $se) = EW::Sys::do("rm -rf $tmpdir");
($so, $se) = EW::Sys::do("mkdir -p $tmpdir");

dbg("Cloning ewmgoe into $ewmgoe", DBGVERBOSE);
($so, $se) = EW::Sys::do("git clone $ewmgoehub $ewmgoe");

foreach my $pkg (keys %pkgs) {
  my ($cat, $repo) = map { $pkgs{$pkg}{$_} } ('cat', 'repo');
  dbg("Iterating: $pkg", DBGVERBOSE);

  my $wkdir = "$tmpdir/$repo";
  my $wkdiropt = "--git-dir=$wkdir/.git --work-tree=$wkdir";

  if (!$repos{$repo}{'cloned'}) {
    dbg("Cloning: $repo into $wkdir", DBGVERBOSE);
    ($so, $se) = EW::Sys::do("git clone $repos{$repo}{'github'} $wkdir", $gitloglevel, $gitloglevel, $gitloglevel);
    $repos{$repo}{'cloned'}++;
  }

  my $branches = $pkgs{$pkg}{'branches'};
  foreach my $br (@$branches) {
    dbg("Iterating: $pkg/$br", DBGVERBOSE);

    dbg("Checkout: $repo/$br", DBGVERBOSE);
    ($so, $se) = EW::Sys::do("git $wkdiropt checkout $br", $gitloglevel, $gitloglevel, $gitloglevel);

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
        $revs{$h}{'bv'} = "99999-pre${seq}";
        $revs{$h}{'arch'} = "~";
      }
    }

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
      dbg("${w}: ${bn}", DBGINFO);
      my $lines = ebuildcontent($pkg, $br, $h, $arch);
      EW::File::writelines($f, $lines);
      push @resultfiles, $f;
    }
  }
}

foreach my $pkg (keys %pkgs) {
  my $d = "$ewmgoe/$pkgs{$pkg}{'cat'}/${pkg}";
  if (mkmanifest($pkg, $d)) {
    push @resultfiles, "${d}/Manifest";
  }
}

if (1 && scalar(@resultfiles)) {
  dbg("Commiting for $nowday: " . scalar(@resultfiles) . " files", DBGINFO);
  ($so, $se) = EW::Sys::do('git $ewmgoeopt add ' . join(' ', @resultfiles), $gitloglevel, $gitloglevel, $gitloglevel);
  die "Git add error: \n" . join("\n", @$so, @$se) if scalar(@$se);
  ($so, $se) = EW::Sys::do("git $ewmgoeopt commit -m 'upstream $nowday'", $gitloglevel, $gitloglevel, $gitloglevel);
  ($so, $se) = EW::Sys::do('git $ewmgoeopt push', $gitloglevel, $gitloglevel, $gitloglevel);
}

exit;

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

sub getdesc {
  my ($h, $wkdiropt) = @_;
  ($so, $se) = EW::Sys::do("git $wkdiropt describe $h", $gitloglevel, $gitloglevel, $gitloglevel);
  my $d = shift @$so;
  $d = '' unless defined $d;
  return $d;
}

sub getbv {
  my $d = shift;
  my ($bv, $arch, $vn, $vntype, $seq) = ('', '', '', '', '');
  if (($vn, $vntype, undef, $seq) = ($d =~ /^[^\d\.]*?([\d\.]+)(pre|)(-([^-]+)-[^-]+)?$/)) {
    $bv = "${vn}" . ($seq ? '-' . ('pre' eq $vntype ? 'pre' : 'p') . $seq : '');
    $arch = ('pre' eq $vntype ? '~' : '');
  }
  my %lhs = ('vn' => $vn
             , 'vntype' => $vntype
             , 'seq' => $seq
             , 'bv' => $bv
             , 'arch' => $arch);
  return \%lhs;
}

# foreach my $line (@$lines); do d=$(git describe $i) ; q0=${d#*-} ; q=${q0%-*} ; f=~/dev/git/ew-mythtv-gentoo/media-tv/mythtv/mythtv-0.24.0.$q.ebuild ; if [ -e $f ] ; then c0=$(grep MYTHCOMMIT ~/dev/git/ew-mythtv-gentoo/media-tv/mythtv/mythtv-0.24.0.$q.ebuild) ; else c0="" ; fi ; echo "$i $d $q $c0" ; done
