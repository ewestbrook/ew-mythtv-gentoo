# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-tv/mythtv/mythtv-0.23_alpha22857.ebuild,v 1.4 2010/03/23 03:43:52 vapier Exp $

EAPI=2
inherit flag-o-matic multilib eutils qt4 toolchain-funcs python versionator

######### ebuild editors take note #########
# $ git checkout branch
# $ HT=$(git log -n 1 --pretty="format:%H %ct") ; echo $HT
########## edit for new versions ###########
MYTHBRANCH="fixes" # select "fixes" for 0.24-fixes et al, or "master" for trunk
GITSTAMP="1291777173" # set to 9999999999 for latest version, integer timestamp for pinned
GITHASH="ee57332927393d071d7b3f1788476f07c77f7e82" # for a numbered version
# GITHASH="" # leave empty for branch's latest version instead
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
EGIT_COMMIT=$([ "" == "${GITHASH}" ] && echo "${GITBRANCH}" || echo "${GITHASH}")
EGIT_BRANCH=$([ "fixes" == "${MYTHBRANCH}" ] && echo "fixes/${MYTHMAJOR}.${MYTHMINOR}" || echo "master")

inherit git
ORIGINAL_S="${S}"

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
  einfo EGIT_REPO_URI: $EGIT_REPO_URI
  einfo EGIT_COMMIT: $EGIT_COMMIT
  einfo EGIT_BRANCH: $EGIT_BRANCH
  einfo ORIGINAL_S: $ORIGINAL_S
  einfo D: $D
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
  dcraw
  debug
  directv
  dvb
  +exif
  fftw
  ieee1394
  jack
  lcd
  lirc
  mmx
  mytharchive
  mythbrowser
  mythgallery
  mythgame
  mythmusic
  mythnews
  mythmusic
  myththemes
  mythvideo
  mythweather
  -mythzoneminder
  mythnetvision
  opengl
  perl
  pulseaudio
  python
  tiff
  vdpau
  ${IUSE_VIDEO_CARDS}
"

# fonts from bug #296222
RDEPEND="
	>=app-cdr/dvd+rw-tools-5.21.4.10.8
	>=dev-lang/python-2.3.5
	>=media-libs/freetype-2.0
	>=media-sound/lame-3.93.1
	>=media-video/dvdauthor-0.6.11
	>=media-video/ffmpeg-0.4.9
	>=media-video/mjpegtools-1.6.2[png]
	>=x11-libs/qt-core-4.4:4[qt3support]
	>=x11-libs/qt-gui-4.4:4[dbus?,qt3support,tiff?]
	>=x11-libs/qt-opengl-4.4:4[qt3support]
	>=x11-libs/qt-sql-4.4:4[qt3support,mysql]
	>=x11-libs/qt-webkit-4.4:4[dbus?]
	alsa? ( >=media-libs/alsa-lib-0.9 )
	css? ( media-libs/libdvdcss )
	dbus? ( >=x11-libs/qt-dbus-4.4:4 )
	dev-python/imaging
	dev-python/mysql-python
	directv? ( virtual/perl-Time-HiRes )
	dvb? ( media-libs/libdvb media-tv/linuxtv-dvb-headers )
	fftw? ( sci-libs/fftw:3.0 )
	ieee1394? (	>=sys-libs/libraw1394-1.2.0 >=sys-libs/libavc1394-0.5.3 >=media-libs/libiec61883-1.0.0 )
	jack? ( media-sound/jack-audio-connection-kit )
	lcd? ( app-misc/lcdproc )
	lirc? ( app-misc/lirc )
	media-fonts/corefonts
	media-fonts/dejavu
	media-video/transcode
	myththemes? ( x11-libs/qt-core:4 )
	perl? ( dev-perl/DBD-mysql )
	pulseaudio? ( >=media-sound/pulseaudio-0.9.7 )
	python? ( dev-python/mysql-python dev-python/lxml )
	vdpau? ( x11-libs/libvdpau )
	virtual/cdrtools
	virtual/glu
	virtual/mysql
	virtual/opengl
	x11-libs/libX11
	x11-libs/libXext
	x11-libs/libXinerama
	x11-libs/libXrandr
	x11-libs/libXv
	x11-libs/libXxf86vm
	|| ( >=net-misc/wget-1.9.1 >=media-tv/xmltv-0.5.43 )
"

DEPEND="${RDEPEND}
	!<media-plugins/mythcontrols-0.24
	!<media-plugins/mythflix-0.24
	!<x11-themes/mythtv-themes-0.24
	!<x11-themes/mythtv-themes-extra-0.24
	>=sys-apps/sed-4
	app-arch/unzip
	mythnetvision? ( dev-python/oauth dev-python/pycurl )
	mythweather? ( dev-perl/DateTime-Format-ISO8601 dev-perl/XML-XPath )
	x11-apps/xinit
	x11-proto/xf86vidmodeproto
	x11-proto/xineramaproto
"

src_unpack() {
	git_src_unpack

	# mythtv
	########
	S="${ORIGINAL_S}/mythtv"
	einfo mythtv section of src_unpack in ${S}
	cd "${S}"
	########

	epatch "${FILESDIR}/${PN}-0.21-ldconfig-sanxbox-fix.patch"
	epatch "${FILESDIR}/${PN}-ew-square-pixels.patch"
}

pkg_setup() {
	enewuser mythtv -1 /bin/bash /home/mythtv ${MYTHTV_GROUPS}
	usermod -a -G video,audio,tty,uucp mythtv
}

src_configure() {

	# mythtv
	########
	S="${ORIGINAL_S}/mythtv"
	einfo mythtv section of src_configure in ${S}
	cd "${S}"
	########

	local myconf="--prefix=/usr
		--mandir=/usr/share/man
		--libdir-name=$(get_libdir)
		--disable-directfb
		--dvb-path=/usr/include
		--enable-opengl-vsync
		--enable-x11
		--enable-xrandr
		--enable-xv
		$(use_enable alsa audio-alsa)
		$(use_enable altivec)
		$(use_enable dvb)
		$(use_enable fftw libfftw3)
		$(use_enable ieee1394 firewire)
		$(use_enable jack audio-jack)
		$(use_enable lirc)
		$(use_enable vdpau)"

	use mmx || use adm64 && mm="en" || mm="dis"
	myconf="${myconf} --${mm}able-mmx"

	use perl && wb="perl" || wb=""
	use python && wb="${wb},python"
	[ "" == "${wb}" ] && wo=out && wb="perl,python" || wo=""
	myconf="${myconf} --with${wo}-bindings=${wb}"

	use debug && ct="debug" || ct="release"
	myconf="${myconf} --compile-type=${ct}"

	hasq distcc ${FEATURES} || myconf="${myconf} --disable-distcc"
	hasq ccache ${FEATURES} || myconf="${myconf} --disable-ccache"

	einfo "Running ./configure ${myconf}"
	sh ./configure ${myconf} || die "configure died"

	# mythplugins
	#############
	S="${ORIGINAL_S}/mythplugins"
	einfo mythplugins section of src_configure in ${S}
	cd "${S}"
	#############

	local myconf1="--prefix=/usr
		--mandir=/usr/share/man
		--libdir-name=$(get_libdir)
		$(use_enable dcraw)
		$(use_enable exif)
		$(use_enable mytharchive)
		$(use_enable mythbrowser)
		$(use_enable mythgallery)
		$(use_enable mythgame)
		$(use_enable mythmusic)
		$(use_enable mythnews)
		$(use_enable mythvideo)
		$(use_enable mythweather)
		$(use_enable mythzoneminder)
		$(use_enable mythnetvision)
		$(use_enable opengl)"

	einfo "Running ./configure ${myconf1}"
	sh ./configure ${myconf1} || die "configure died"
}

src_compile() {

	# mythtv
	########
	S="${ORIGINAL_S}/mythtv"
	einfo mythtv section of src_compile in ${S}
	cd "${S}"
	########

	emake || die "mythtv emake failed"

	# mythplugins
	########
	S="${ORIGINAL_S}/mythplugins"
	einfo mythplugins section of src_compile in ${S}
	cd "${S}"
	########

	emake || die "mythplugins emake failed"
}

src_install() {

	# mythtv
	########
	S="${ORIGINAL_S}/mythtv"
	einfo mythtv install section of src_install in ${S}
	cd "${S}"
	########

	einfo installing to INSTALL_ROOT: "${D}"
	make INSTALL_ROOT="${D}" install || die "install failed"
	dodoc AUTHORS FAQ UPGRADING README
	newinitd "${FILESDIR}"/mythbackend.rc mythbackend
	newconfd "${FILESDIR}"/mythbackend.conf mythbackend
	dodir /var/log/mythtv
	fowners mythtv:mythtv /var/log/mythtv
	dodir /var/service/mythbackend
	exeinto /var/service/mythbackend
	newexe "${FILESDIR}"/mythbackend.run run

	# mythplugins
	#############
	S="${ORIGINAL_S}/mythplugins"
	einfo mythplugins section of src_install in ${S}
	cd "${S}"
	#############

	einfo installing to INSTALL_ROOT: "${D}"
	make INSTALL_ROOT="${D}" install || die "install failed"
	# einstall INSTALL_ROOT="${D}" || die "install failed"
	fperms 0775 /usr/share/mythtv/mythvideo/scripts/jamu.py
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
