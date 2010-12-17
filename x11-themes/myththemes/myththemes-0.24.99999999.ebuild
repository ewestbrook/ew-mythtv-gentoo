##########################################
# EW MythTV Gentoo Overlay Ebuilds       #
# github.com/ewestbrook/ew-mythtv-gentoo #
# E. Westbrook <ewmgoe@westbrook.com>    #
##########################################

EAPI=2
inherit qt4 versionator

MYTHBRANCH="fixes"
GITHASH=""
inherit ew-myththemes

HOMEPAGE="http://www.mythtv.org"
LICENSE="GPL-2"
RESTRICT="nomirror strip"
DESCRIPTION="Homebrew PVR project"
SLOT="0"
KEYWORDS="~amd64 ~ppc ~x86"
