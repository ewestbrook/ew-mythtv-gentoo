##########################################
# EW MythTV Gentoo Overlay Ebuilds       #
# github.com/ewestbrook/ew-mythtv-gentoo #
# E. Westbrook <ewmgoe@westbrook.com>    #
##########################################

EAPI=2
inherit flag-o-matic multilib eutils qt4 toolchain-funcs python versionator

MYTHBRANCH="fixes"
GITHASH="6754905e6dc910cef5207e11fb8355a5ac67bd3b"
inherit ew-mythplugins

HOMEPAGE="http://www.mythtv.org"
LICENSE="GPL-2"
RESTRICT="nomirror strip"
DESCRIPTION="Homebrew PVR project"
SLOT="0"
KEYWORDS="amd64 ppc x86"
