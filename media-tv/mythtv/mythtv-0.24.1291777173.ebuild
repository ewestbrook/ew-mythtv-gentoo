# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-tv/mythtv/mythtv-0.23_alpha22857.ebuild,v 1.4 2010/03/23 03:43:52 vapier Exp $

EAPI=2
inherit flag-o-matic multilib eutils qt4 toolchain-funcs python versionator

######### ebuild editors take note #########
# $ git checkout branch
# $ HT=$(git log -n 1 --pretty="format:%H %ct") ; echo $HT
########## edit for new versions ###########
GITBRANCH="fixes/0.24"
GITSTAMP="1291777173" # set to 9999999999 for latest version, integer timestamp for pinned
GITHASH="ee57332927393d071d7b3f1788476f07c77f7e82" # for a numbered version
# GITHASH="$GITBRANCH" # for branch's latest version instead
############################################

HOMEPAGE="http://www.mythtv.org"
LICENSE="GPL-2"
RESTRICT="nomirror strip"
DESCRIPTION="Homebrew PVR project"
SLOT="0"
KEYWORDS="amd64 ppc x86"
MY_PN="MythTV"
VC=( $(get_all_version_components ${PV}) )
MYTHMAJOR="${VC[0]}"
MYTHMINOR="${VC[2]}"
EBSTAMP="${VC[4]}"
GITBRIEF=${GITHASH:0:7}

[ "$EBSTAMP" == "$GITSTAMP" ] || die "Git timestamp integer doesn't \
match this ebuild's filenamed version.  If you are creating a new \
ebuild for an updated version, be sure to edit the ebuild and insert \
the correct timestamp and commit hash."

EGIT_REPO_URI="git://github.com/MythTV/mythtv"
EGIT_COMMIT="$GITHASH"
EGIT_BRANCH="$GITBRANCH"
inherit git

if /bin/true ; then
  einfo P: $P
  einfo PN: $PN
  einfo PV: $PV
  einfo MY_PN: $MY_PN
  for ((n=0; n < ${#VC[*]}; n++)) ; do
	  einfo VC[$n]: ${VC[$n]}
  done
  einfo MYTHMAJOR: $MYTHMAJOR
  einfo MYTHMINOR: $MYTHMINOR
  einfo EBSTAMP: $EBSTAMP
  einfo GITSTAMP: $GITSTAMP
  einfo GITHASH: $GITHASH
  einfo GITBRIEF: $GITBRIEF
  einfo SRC_URI: $SRC_URI
  einfo S: $S
fi

IUSE_VIDEO_CARDS="\
  video_cards_nvidia \
  video_cards_via \
"

IUSE="
  alsa
  altivec
  +css
  dbus
  debug
  directv
  dvb
  fftw
  ieee1394
  jack
  lcd
  lirc
  mmx
  perl
  pulseaudio
  python
  tiff
  vdpau
  xvmc
  ${IUSE_VIDEO_CARDS}
"

# fonts from bug #296222
RDEPEND="media-fonts/corefonts
	media-fonts/dejavu
	>=media-libs/freetype-2.0
	>=media-sound/lame-3.93.1
	x11-libs/libX11
	x11-libs/libXext
	x11-libs/libXinerama
	x11-libs/libXv
	x11-libs/libXrandr
	x11-libs/libXxf86vm
	>=x11-libs/qt-core-4.4:4[qt3support]
	>=x11-libs/qt-gui-4.4:4[dbus?,qt3support,tiff?]
	>=x11-libs/qt-sql-4.4:4[qt3support,mysql]
	>=x11-libs/qt-opengl-4.4:4[qt3support]
	>=x11-libs/qt-webkit-4.4:4[dbus?]
	virtual/mysql
	virtual/opengl
	virtual/glu
	|| ( >=net-misc/wget-1.9.1 >=media-tv/xmltv-0.5.43 )
	alsa? ( >=media-libs/alsa-lib-0.9 )
	css? ( media-libs/libdvdcss )
	dbus? ( >=x11-libs/qt-dbus-4.4:4 )
	directv? ( virtual/perl-Time-HiRes )
	dvb? ( media-libs/libdvb media-tv/linuxtv-dvb-headers )
	fftw? ( sci-libs/fftw:3.0 )
	ieee1394? (	>=sys-libs/libraw1394-1.2.0
			>=sys-libs/libavc1394-0.5.3
			>=media-libs/libiec61883-1.0.0 )
	jack? ( media-sound/jack-audio-connection-kit )
	lcd? ( app-misc/lcdproc )
	lirc? ( app-misc/lirc )
	perl? ( dev-perl/DBD-mysql )
	pulseaudio? ( >=media-sound/pulseaudio-0.9.7 )
	python? ( dev-python/mysql-python
			dev-python/lxml )
	vdpau? ( x11-libs/libvdpau )
	xvmc? ( x11-libs/libXvMC )"

DEPEND="${RDEPEND}
	app-arch/unzip
	x11-proto/xineramaproto
	x11-proto/xf86vidmodeproto
	x11-apps/xinit
	!<media-plugins/mythcontrols-0.24
	!<x11-themes/mythtv-themes-0.24
	!<x11-themes/mythtv-themes-extra-0.24
	!<media-plugins/mythflix-0.24"

src_unpack() {
	git_src_unpack
	S="${S}/${PN}"
	cd "${S}"
	epatch "${FILESDIR}/${PN}-0.21-ldconfig-sanxbox-fix.patch"
	epatch "${FILESDIR}/${PN}-ew-square-pixels.patch"
}

pkg_setup() {
	enewuser mythtv -1 /bin/bash /home/mythtv ${MYTHTV_GROUPS}
	usermod -a -G video,audio,tty,uucp mythtv
}

src_configure() {
	local myconf="--prefix=/usr
		--mandir=/usr/share/man
		--libdir-name=$(get_libdir)"

	use altivec || myconf="${myconf} --disable-altivec"
	use alsa || myconf="${myconf} --disable-audio-alsa"
	use fftw && myconf="${myconf} --enable-libfftw3"
	use jack || myconf="${myconf} --disable-audio-jack"
	use vdpau && myconf="${myconf} --enable-vdpau"
	use xvmc && myconf="${myconf} --enable-xvmc --enable-xvmcw"

	myconf="${myconf}
		$(use_enable dvb)
		$(use_enable ieee1394 firewire)
		$(use_enable lirc)
		--disable-directfb
		--dvb-path=/usr/include
		--enable-opengl-vsync
		--enable-xrandr
		--enable-xv
		--enable-x11"

	if use mmx || use amd64; then
		myconf="${myconf} --enable-mmx"
	else
		myconf="${myconf} --disable-mmx"
	fi

	if use perl && use python; then
		myconf="${myconf} --with-bindings=perl,python"
	elif use perl; then
		myconf="${myconf} --with-bindings=perl"
	elif use python; then
		myconf="${myconf} --with-bindings=python"
	else
		myconf="${myconf} --without-bindings=perl,python"
	fi

	if use debug; then
		myconf="${myconf} --compile-type=debug"
	else
		myconf="${myconf} --compile-type=release"
	fi

	hasq distcc ${FEATURES} || myconf="${myconf} --disable-distcc"
	hasq ccache ${FEATURES} || myconf="${myconf} --disable-ccache"

	einfo "Running ./configure ${myconf}"
	sh ./configure ${myconf} || die "configure died"

	# for some reason the .sh files don't come executable when fetched in zip format
	chmod -v +x $(find "${S}" -name '*.sh')
}

src_compile() {
	emake || die "emake failed"
}

src_install() {
	einfo installing to INSTALL_ROOT: "${D}"
	make INSTALL_ROOT="${D}" install || die "install failed"
	dodoc AUTHORS FAQ UPGRADING README
	newinitd "${FILESDIR}"/mythbackend-"${VC[0]}"."${VC[2]}".rc mythbackend
	newconfd "${FILESDIR}"/mythbackend-"${VC[0]}"."${VC[2]}".conf mythbackend
	dodir /var/log/mythtv
	fowners mythtv:mythtv /var/log/mythtv
	dodir /var/service/mythbackend
	exeinto /var/service/mythbackend
	newexe "${FILESDIR}"/mythbackend-"${VC[0]}"."${VC[2]}".run run
}

pkg_postinst() {
	use python && python_mod_optimize $(python_get_sitedir)/MythTV
}

pkg_postrm() {
	use python && python_mod_cleanup $(python_get_sitedir)/MythTV
}

pkg_info() {
	"${ROOT}/usr/bin/mythfrontend" --version
}
