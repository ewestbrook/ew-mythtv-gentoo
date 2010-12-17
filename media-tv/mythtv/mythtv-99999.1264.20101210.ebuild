##########################################
# EW MythTV Gentoo Overlay Ebuilds       #
# github.com/ewestbrook/ew-mythtv-gentoo #
# E. Westbrook <ewmgoe@westbrook.com>    #
##########################################

EAPI=2
inherit flag-o-matic multilib eutils qt4 toolchain-funcs python versionator

MYTHBRANCH="master"
GITHASH="834816855a2e6f38b388a597952807f4474f4ec1"
inherit ew-mythtv

HOMEPAGE="http://www.mythtv.org"
LICENSE="GPL-2"
RESTRICT="nomirror strip"
DESCRIPTION="Homebrew PVR project"
KEYWORDS="~amd64 ~ppc ~x86"
SLOT="0"
