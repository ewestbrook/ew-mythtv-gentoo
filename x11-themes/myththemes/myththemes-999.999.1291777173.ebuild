##########################################
# EW MythTV Gentoo Overlay Ebuilds       #
# github.com/ewestbrook/ew-mythtv-gentoo #
# E. Westbrook <ewmgoe@westbrook.com>    #
##########################################

EAPI=2
inherit qt4 versionator

MYTHBRANCH="master"
GITSTAMP="1291777173"
GITHASH="45d6b633fba2da200810e0ce7a0c1f6732645b30"
inherit myththemes-1

HOMEPAGE="http://www.mythtv.org"
DESCRIPTION="A collection of themes for the MythTV project."
LICENSE="GPL-2"
RESTRICT="nomirror"
SLOT="0"
KEYWORDS="~amd64 ~ppc ~x86"
