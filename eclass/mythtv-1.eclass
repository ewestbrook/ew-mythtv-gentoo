##########################################
# EW MythTV Gentoo Overlay Ebuilds       #
# github.com/ewestbrook/ew-mythtv-gentoo #
# E. Westbrook <ewmgoe@westbrook.com>    #
##########################################

IUSE_VIDEO_CARDS="
  video_cards_nvidia
  video_cards_via
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
  ${IUSE_VIDEO_CARDS}
"

RDEPEND="
	media-fonts/corefonts
	media-fonts/dejavu
	media-libs/freetype:2
	media-sound/lame
	x11-libs/libX11
	x11-libs/libXext
	x11-libs/libXinerama
	x11-libs/libXv
	x11-libs/libXrandr
	x11-libs/libXxf86vm
	x11-libs/qt-core:4[qt3support]
	x11-libs/qt-gui:4[dbus?,qt3support,tiff?]
	x11-libs/qt-sql:4[qt3support,mysql]
	x11-libs/qt-opengl:4[qt3support]
	x11-libs/qt-webkit:4[dbus?]
	virtual/mysql
	virtual/opengl
	virtual/glu
	|| ( net-misc/wget media-tv/xmltv )
	alsa? ( media-libs/alsa-lib )
	css? ( media-libs/libdvdcss )
	dbus? ( x11-libs/qt-dbus:4 )
	directv? ( virtual/perl-Time-HiRes )
	dvb? ( media-libs/libdvb media-tv/linuxtv-dvb-headers )
	fftw? ( sci-libs/fftw:3.0 )
	ieee1394? (	sys-libs/libraw1394 sys-libs/libavc1394 media-libs/libiec61883 )
	jack? ( media-sound/jack-audio-connection-kit )
	lcd? ( app-misc/lcdproc )
	lirc? ( app-misc/lirc )
	perl? ( dev-perl/DBD-mysql )
	pulseaudio? ( media-sound/pulseaudio )
	python? ( dev-python/mysql-python dev-python/lxml )
	vdpau? ( x11-libs/libvdpau )
"

DEPEND="
	${RDEPEND}
	app-arch/unzip
	x11-proto/xineramaproto
	x11-proto/xf86vidmodeproto
	x11-apps/xinit
"

MY_PN="MythTV"
VC=( $(get_all_version_components ${PV}) )
MYTHMAJOR="${VC[0]}"
MYTHMINOR="${VC[2]}"
EBSTAMP="${VC[4]}"
GITBRIEF=${GITHASH:0:7}

[ "$EBSTAMP" == "$GITSTAMP" ] || die "In-ebuild timestamp integer doesn't filename's.  Edit ebuild."

EGIT_REPO_URI="git://github.com/${MY_PN}/${PN}"
EGIT_COMMIT=$([ "" == "${GITHASH}" ] && echo "${GITBRANCH}" || echo "${GITHASH}")
EGIT_BRANCH=$([ "fixes" == "${MYTHBRANCH}" ] && echo "fixes/${MYTHMAJOR}.${MYTHMINOR}" || echo "master")

inherit git
ORIGINAL_S="${S}"

if /bin/false ; then
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

src_unpack() {
	git_src_unpack
	S="${ORIGINAL_S}/mythtv"
	cd "${S}"
	epatch "${FILESDIR}/${PN}-0.21-ldconfig-sanxbox-fix.patch"
	epatch "${FILESDIR}/${PN}-ew-square-pixels.patch"
}

pkg_setup() {
	enewuser mythtv -1 /bin/bash /home/mythtv ${MYTHTV_GROUPS}
	usermod -a -G video,audio,tty,uucp mythtv
}

src_configure() {
	local myconf="
		$(use_enable alsa audio-alsa)
		$(use_enable altivec)
		$(use_enable dvb)
		$(use_enable fftw libfftw3)
		$(use_enable ieee1394 firewire)
		$(use_enable jack audio-jack)
		$(use_enable lirc)
		$(use_enable vdpau)
		--disable-directfb
		--dvb-path=/usr/include
		--enable-opengl-vsync
		--enable-x11
		--enable-xrandr
		--enable-xv
		--libdir-name=$(get_libdir)
		--mandir=/usr/share/man
		--prefix=/usr
"

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
}

src_compile() {
	emake || die "emake failed"
}

src_install() {
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
