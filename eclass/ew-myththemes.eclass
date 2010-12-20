##########################################
# EW MythTV Gentoo Overlay Ebuilds       #
# github.com/ewestbrook/ew-mythtv-gentoo #
# E. Westbrook <ewmgoe@westbrook.com>    #
##########################################

EAPI=2
inherit eutils versionator flag-o-matic multilib qt4 toolchain-funcs python

EGIT_PROJECT="myththemes"
DESCRIPTION="Themes for MythTV"
SLOT="0"
inherit ew-mythtv-base

IUSE=""

DEPEND="
  x11-libs/qt-core:4
  >=media-tv/mythtv-${PV}
"
RDEPEND="${DEPEND}"

src_configure() {
	cd "${S}"
	sh ./configure --prefix=/usr || die "configure died"
}

src_compile() {
	emake || die "emake failed"
}

src_install() {
	einstall INSTALL_ROOT="${D}" || die "install failed"
}
