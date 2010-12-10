##########################################
# EW MythTV Gentoo Overlay Ebuilds       #
# github.com/ewestbrook/ew-mythtv-gentoo #
# E. Westbrook <ewmgoe@westbrook.com>    #
##########################################

EAPI=2
inherit webapp depend.php versionator

MYTHBRANCH="fixes"
GITSTAMP="1291777173"
GITHASH="52cb8fb98f1aa209cfd2befa92a9cdd0b7841070"
inherit mythweb-1

HOMEPAGE="http://www.mythtv.org"
DESCRIPTION="PHP scripts intended to manage MythTV from a web browser."
LICENSE="GPL-2"
RESTRICT="nomirror"
KEYWORDS="amd64 ppc x86"
