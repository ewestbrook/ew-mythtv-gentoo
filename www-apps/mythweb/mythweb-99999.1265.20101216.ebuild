##########################################
# EW MythTV Gentoo Overlay Ebuilds       #
# github.com/ewestbrook/ew-mythtv-gentoo #
# E. Westbrook <ewmgoe@westbrook.com>    #
##########################################

EAPI=2
inherit webapp depend.php versionator

MYTHBRANCH="master"
GITHASH="4753643423312953aa303e91b5a1fce11a4f9759"
inherit ew-mythweb

HOMEPAGE="http://www.mythtv.org"
LICENSE="GPL-2"
RESTRICT="nomirror strip"
DESCRIPTION="Homebrew PVR project"
KEYWORDS="~amd64 ~ppc ~x86"
