##########################################
# EW MythTV Gentoo Overlay Ebuilds       #
# github.com/ewestbrook/ew-mythtv-gentoo #
# E. Westbrook <ewmgoe@westbrook.com>    #
##########################################

EAPI=2
inherit qt4 versionator

MYTHBRANCH="fixes"
GITSTAMP="1291777173"
GITHASH="1c84b134711163ef613c8d8567baf29fd31c41a6"
inherit myththemes-1

HOMEPAGE="http://www.mythtv.org"
DESCRIPTION="A collection of themes for the MythTV project."
LICENSE="GPL-2"
RESTRICT="nomirror"
SLOT="0"
KEYWORDS="amd64 ppc x86"
