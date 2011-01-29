#!/usr/bin/perl -w

use lib '/ds2/home/eric/dev/perl/EW/lib';

use EW::Debug;
use EW::File;
use EW::Sys;
use EW::Time;
use File::Basename;

EW::Time::p('TZ' => 'UTC');
$ENV{'TZ'} = 'UTC';
my $nowday = EW::Time->now->tostring('%Y%m%d');

my @resultfiles = ();

my $maxrevs = 10;
my $gitloglevel = DBGVERBOSE;
my $devdir = '/ds2/home/eric/dev';
my $mythdir = "$devdir/mythtv/src/git";
my $ewmgoe = "$devdir/git/ew-mythtv-gentoo";

my ($so, $se);

%pkgs = ('mythtv' => { 'cat' => 'media-tv'
                       , 'repo' => 'mythtv'
                       , 'branches' => { 'fixes/0.23' => { 'prefix' => '', 'arch' => '' }
                                         , 'fixes/0.24' => { 'prefix' => '', 'arch' => '' }
                                         , 'master' => { 'prefix' => '99999', 'arch' => '~' } } }
         , 'mythplugins' => { 'cat' => 'media-plugins'
                              , 'repo' => 'mythtv'
                              , 'branches' => { 'fixes/0.23' => { 'prefix' => '', 'arch' => '' }
                                                , 'fixes/0.24' => { 'prefix' => '', 'arch' => '' }
                                                , 'master' => { 'prefix' => '99999', 'arch' => '~' } } }
         , 'mythweb' => { 'cat' => 'www-apps'
                          , 'repo' => 'mythweb'
                          , 'branches' => { 'fixes/0.23' => { 'prefix' => '0.23.1', 'arch' => '' }
                                            , 'fixes/0.24' => { 'prefix' => '0.24.0', 'arch' => '' }
                                            , 'master' => { 'prefix' => '99999', 'arch' => '~' } } }
         , 'myththemes' => { 'cat' => 'x11-themes'
                             , 'repo' => 'myththemes'
                             , 'branches' => { 'fixes/0.23' => { 'prefix' => '0.23.1', 'arch' => '' }
                                               , 'fixes/0.24' => { 'prefix' => '0.24.0', 'arch' => '' }
                                               , 'master' => { 'prefix' => '99999', 'arch' => '~' } } }
         , 'nuvexport' => { 'cat' => 'media-video'
                             , 'repo' => 'nuvexport'
                             , 'branches' => { 'fixes/0.23' => { 'prefix' => '0.23.1', 'arch' => '' }
                                               , 'fixes/0.24' => { 'prefix' => '0.24.0', 'arch' => '' }
                                               , 'master' => { 'prefix' => '99999', 'arch' => '~' } } }
        );

# my $cat = 'media-tv';
# my $pkg = 'mythtv';
# my $br = 'fixes/0.24';
# my $repo = 'mythtv';
# my $arch = '';

foreach my $pkg (keys %pkgs) {
  my ($cat, $repo) = map { $pkgs{$pkg}{$_} } ('cat', 'repo');
  dbg("===== $pkg =====");
  dbg("pkg $pkg, cat $cat, repo $repo", $gitloglevel);

  chdir("$mythdir/$repo");
  dbg("Fetching: $repo", $gitloglevel);
  ($so, $se) = EW::Sys::do("git fetch", $gitloglevel, $gitloglevel);

  my $branches = $pkgs{$pkg}{'branches'};
  foreach my $br (keys %$branches) {
    my ($prefix, $arch) = map { $branches->{$br}{$_} } ('prefix', 'arch');
    dbg("$pkg branch $br, prefix \"$prefix\", arch \"$arch\"", $gitloglevel);

    dbg("Reset: $repo/$br", $gitloglevel);
    ($so, $se) = EW::Sys::do("git reset --hard", $gitloglevel, $gitloglevel);

    dbg("Clean: $repo/$br", $gitloglevel);
    ($so, $se) = EW::Sys::do("git clean -fxd", $gitloglevel, $gitloglevel);

    dbg("Checkout: $repo/$br", $gitloglevel);
    ($so, $se) = EW::Sys::do("git checkout $br", $gitloglevel, $gitloglevel);

    dbg("Pull: origin/$br", $gitloglevel);
    ($so, $se) = EW::Sys::do("git pull", $gitloglevel, $gitloglevel);

    dbg("$repo/$br: Scraping recent log", $gitloglevel);
    my ($hashes, $se) = EW::Sys::do("git log -n$maxrevs --pretty=\"format:%H\"", $gitloglevel, $gitloglevel);

    dbg("$repo/$br: Describing recent commits", $gitloglevel);
    my %revs = map { $_ => { 'desc' => (EW::Sys::do("git describe $_", $gitloglevel, $gitloglevel))[0][0] } } @$hashes;

    dbg("$repo/$br: Scraping full log", $gitloglevel);
    my ($allhashes, $se1) = EW::Sys::do("git log --reverse --pretty=\"format:%H\"", $gitloglevel, $gitloglevel);
    dbg("$repo/$br: Total commits: " . scalar(@$allhashes));

    dbg("$repo/$br: Indexing full log", $gitloglevel);
    my $i = 0;
    my %baserevs = map { $_ => $i++ } @$allhashes;

    foreach my $rev (keys %revs) {

      if (!$revs{$rev}{'desc'} || 'master' eq $br) {

        $revs{$rev}{'major'} = '';
        $revs{$rev}{'minor'} = '';
        $revs{$rev}{'superminor'} = '';
        $revs{$rev}{'seq'} = $baserevs{$rev};

      } else {

        ($revs{$rev}{'major'}
         , $revs{$rev}{'minor'}
         , $revs{$rev}{'superminor'}
         , $revs{$rev}{'suffix'}
         , undef
         , $revs{$rev}{'seq'})
          = ($revs{$rev}{'desc'} =~ /[vb](\d+)(\.\d+)(\.\d+)?(.*?)(-(\d+)-g)?/);

        foreach my $i ('major', 'minor') {
          if (!defined $revs{$rev}{$i}) {
            die "Can't parse rev for $i: " . $revs{$rev}{'desc'};
          }
        }

      $revs{$rev}{'superminor'} = '.0' unless $revs{$rev}{'superminor'};
      $revs{$rev}{'seq'} = '0' unless $revs{$rev}{'seq'};

      }

      $revs{$rev}{'suffix'} = '' unless $revs{$rev}{'suffix'};
    }

    REV: foreach my $h (keys %revs) {
      my ($desc, $major, $minor, $superminor, $seq) = map { $revs{$h}{$_} } ('desc', 'major', 'minor', 'superminor', 'seq');
      my $bv = "${prefix}${major}${minor}${superminor}.${seq}";
      my $bn = "${pkg}-${bv}";
      my $d = "${ewmgoe}/${cat}/${pkg}";
      my $f = "${d}/${bn}.ebuild";
      my $w = 'Writing ';
      dbg("Consider: $bn", $gitloglevel);
      if (-e $f) {
        my $lines = EW::File::readlines($f);
        my ($hashline) = grep(/MYTHCOMMIT/, @$lines);
        my ($fh) = ($hashline =~ /\"(.*)\"/);
        if ($fh ne $h) {
          my $hi = $baserevs{$h};
          my $fhi = $baserevs{$fh};
          if ($hi > $fhi) {
            $w = 'Updating';
          } else {
            dbg("Later OK: $bn ($hi) <= $fhi", $gitloglevel);
            next REV;
          }
        } else {
          dbg("Good    : $bn", $gitloglevel);
          next REV;
        }
      }
      my @globbers = glob("${ewmgoe}/${cat}/${pkg}/${pkg}-${prefix}${major}*.ebuild");
      foreach my $fq (@globbers) {
        my $lines = EW::File::readlines($fq);
        my ($hashline) = grep(/$h/, @$lines);
        if ($hashline) {
          die "Ebuild for $bn would duplicate " . basename($fq);
        }
      }
      dbg("${w}: ${bn}");
      my $lines = ebuildcontent($pkg, $br, $h, $arch);
      EW::File::writelines($f, $lines);
      push @resultfiles, "$pkgs{$pkg}{'cat'}/${pkg}/${bn}.ebuild";
    }
  }
}

foreach my $pkg (keys %pkgs) {
  if (mkmanifest($pkg, "$ewmgoe/$pkgs{$pkg}{'cat'}/${pkg}")) {
    push @resultfiles, "$pkgs{$pkg}{'cat'}/${pkg}/Manifest";
  }
}

if (scalar(@resultfiles)) {
  dbg("Commiting for $nowday");
  chdir($ewmgoe);
  ($so, $se) = EW::Sys::do('git add ' . join(' ', @resultfiles));
  ($so, $se) = EW::Sys::do("git commit -m 'upstream $nowday'");
  ($so, $se) = EW::Sys::do('git push');
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
  dbg("Updating Manifest: $pkg");
  chdir($pewmgoe);
  my ($pi, $pe) = EW::Sys::do("ebuild $fname digest");
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

# foreach my $line (@$lines); do d=$(git describe $i) ; q0=${d#*-} ; q=${q0%-*} ; f=~/dev/git/ew-mythtv-gentoo/media-tv/mythtv/mythtv-0.24.0.$q.ebuild ; if [ -e $f ] ; then c0=$(grep MYTHCOMMIT ~/dev/git/ew-mythtv-gentoo/media-tv/mythtv/mythtv-0.24.0.$q.ebuild) ; else c0="" ; fi ; echo "$i $d $q $c0" ; done
