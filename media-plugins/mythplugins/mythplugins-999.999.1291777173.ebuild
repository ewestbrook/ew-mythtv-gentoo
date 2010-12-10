##########################################
# EW MythTV Gentoo Overlay Ebuilds       #
# github.com/ewestbrook/ew-mythtv-gentoo #
# E. Westbrook <ewmgoe@westbrook.com>    #
##########################################

EAPI=2
inherit flag-o-matic multilib eutils qt4 toolchain-funcs python versionator

MYTHBRANCH="master"
GITSTAMP="1291777173"
GITHASH="b674e521028d49193c7d52fa749c556f423cd9f8"
inherit mythplugins-1

HOMEPAGE="http://www.mythtv.org"
LICENSE="GPL-2"
RESTRICT="nomirror strip"
DESCRIPTION="MythTV Plugins"
SLOT="0"
KEYWORDS="~amd64 ~ppc ~x86"
