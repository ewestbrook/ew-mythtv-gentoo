##########################################
# EW MythTV Gentoo Overlay Ebuilds       #
# github.com/ewestbrook/ew-mythtv-gentoo #
# E. Westbrook <ewmgoe@westbrook.com>    #
##########################################

EAPI=2
inherit flag-o-matic multilib eutils qt4 toolchain-funcs python versionator

MYTHBRANCH="fixes"
GITSTAMP="1291777173"
GITHASH="ee57332927393d071d7b3f1788476f07c77f7e82"
inherit mythplugins-1

HOMEPAGE="http://www.mythtv.org"
LICENSE="GPL-2"
RESTRICT="nomirror strip"
DESCRIPTION="MythTV Plugins"
SLOT="0"
KEYWORDS="amd64 ppc x86"
