##########################################
# EW MythTV Gentoo Overlay Ebuilds       #
# github.com/ewestbrook/ew-mythtv-gentoo #
# E. Westbrook <ewmgoe@westbrook.com>    #
##########################################

EAPI=2
inherit qt4 versionator

MYTHBRANCH="fixes"
GITHASH="1c84b134711163ef613c8d8567baf29fd31c41a6"
inherit ew-myththemes

HOMEPAGE="http://www.mythtv.org"
LICENSE="GPL-2"
RESTRICT="nomirror strip"
DESCRIPTION="Homebrew PVR project"
KEYWORDS="amd64 ppc x86"
SLOT="0"
