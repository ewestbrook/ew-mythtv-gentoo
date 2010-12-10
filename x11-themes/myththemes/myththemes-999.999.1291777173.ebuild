# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

##########################################
# EW MythTV Gentoo Overlay Ebuilds       #
# github.com/ewestbrook/ew-mythtv-gentoo #
# E. Westbrook <ewmgoe@westbrook.com>    #
##########################################

EAPI=2
inherit qt4 versionator

MYTHBRANCH="master"
GITSTAMP="1291777173"
GITHASH="1c84b134711163ef613c8d8567baf29fd31c41a6"

HOMEPAGE="http://www.mythtv.org"
DESCRIPTION="A collection of themes for the MythTV project."
LICENSE="GPL-2"
RESTRICT="nomirror"
SLOT="0"
KEYWORDS="amd64 ppc x86"

MY_PN="MythTV"
VC=( $(get_all_version_components ${PV}) )
MYTHMAJOR="${VC[0]}"
MYTHMINOR="${VC[2]}"
EBSTAMP="${VC[4]}"
GITBRIEF=${GITHASH:0:7}

IUSE=""

DEPEND="
  x11-libs/qt-core:4
  =media-tv/mythtv-${PV}
"

EGIT_REPO_URI="git://github.com/${MY_PN}/${PN}"
EGIT_COMMIT=$([ "" == "${GITHASH}" ] && echo "${GITBRANCH}" || echo "${GITHASH}")
EGIT_BRANCH=$([ "fixes" == "${MYTHBRANCH}" ] && echo "fixes/${MYTHMAJOR}.${MYTHMINOR}" || echo "master")

inherit git

if /bin/false ; then
  einfo P: $P
  einfo PN: $PN
  einfo PV: $PV
  einfo MY_PN: $MY_PN
  for ((n=0; n < ${#VC[*]}; n++)) ; do
	  einfo VC[$n]: ${VC[$n]}
  done
  einfo MYTHMAJOR: $MYTHMAJOR
  einfo MYTHMINOR: $MYTHMINOR
  einfo EBSTAMP: $EBSTAMP
  einfo GITSTAMP: $GITSTAMP
  einfo GITHASH: $GITHASH
  einfo GITBRIEF: $GITBRIEF
  einfo SRC_URI: $SRC_URI
  einfo EGIT_REPO_URI: $EGIT_REPO_URI
  einfo EGIT_COMMIT: $EGIT_COMMIT
  einfo EGIT_BRANCH: $EGIT_BRANCH
  einfo ORIGINAL_S: $ORIGINAL_S
  einfo D: $D
fi

src_configure() {
	cd "${S}"
	sh ./configure --prefix=/usr || die "configure died"
}

src_compile() {
	emake || die "emake failed"
}

src_install() {
	einstall INSTALL_ROOT="${D}" || die "install failed"
	for i in /ds2/home/eric/dev/mythtv/themes/* ; do
		j=$(basename $i)
		einfo Symlinking user theme: $j
		# dosym /usr/share/mythtv/themes/$j /ds2/home/eric/dev/mythtv/themes/$j
	done
}
