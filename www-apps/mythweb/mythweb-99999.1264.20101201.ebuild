##########################################
# EW MythTV Gentoo Overlay Ebuilds       #
# github.com/ewestbrook/ew-mythtv-gentoo #
# E. Westbrook <ewmgoe@westbrook.com>    #
##########################################

EAPI=2
inherit webapp depend.php versionator

MYTHBRANCH="master"
GITHASH="34c340c20029ccf923a0e5d8b1438e06005d787b"
inherit ew-mythweb

HOMEPAGE="http://www.mythtv.org"
LICENSE="GPL-2"
RESTRICT="nomirror strip"
DESCRIPTION="Homebrew PVR project"
KEYWORDS="~amd64 ~ppc ~x86"
