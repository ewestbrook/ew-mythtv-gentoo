##########################################
# EW MythTV Gentoo Overlay Ebuilds       #
# github.com/ewestbrook/ew-mythtv-gentoo #
# E. Westbrook <ewmgoe@westbrook.com>    #
##########################################

EAPI=2
inherit webapp depend.php versionator

MYTHBRANCH="fixes"
GITHASH="52cb8fb98f1aa209cfd2befa92a9cdd0b7841070"
inherit mythweb-1

HOMEPAGE="http://www.mythtv.org"
LICENSE="GPL-2"
RESTRICT="nomirror strip"
DESCRIPTION="Homebrew PVR project"
KEYWORDS="amd64 ppc x86"
