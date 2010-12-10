##########################################
# EW MythTV Gentoo Overlay Ebuilds       #
# github.com/ewestbrook/ew-mythtv-gentoo #
# E. Westbrook <ewmgoe@westbrook.com>    #
##########################################

EAPI=2
inherit webapp depend.php versionator

MYTHBRANCH="master"
GITSTAMP="1291777173"
GITHASH="4753643423312953aa303e91b5a1fce11a4f9759"
inherit mythweb-1

HOMEPAGE="http://www.mythtv.org"
DESCRIPTION="PHP scripts intended to manage MythTV from a web browser."
LICENSE="GPL-2"
RESTRICT="nomirror"
SLOT="0"
KEYWORDS="~amd64 ~ppc ~x86"
