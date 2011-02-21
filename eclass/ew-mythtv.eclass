##########################################
# EW MythTV Gentoo Overlay Ebuilds       #
# github.com/ewestbrook/ew-mythtv-gentoo #
# E. Westbrook <ewmgoe@westbrook.com>    #
##########################################

EAPI=2
inherit eutils versionator flag-o-matic multilib qt4 toolchain-funcs python

EGIT_PROJECT="mythtv"
DESCRIPTION="Homebrew PVR project"
SLOT="0"
inherit ew-mythtv-base

IUSE_VIDEO_CARDS="
  video_cards_nvidia
  video_cards_via
"

IUSE="
  alsa
  altivec
 +css
  daemontools
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
	media-fonts/liberation-fonts
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
	daemontools? ( sys-process/daemontools )
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

src_unpack() {
	git_src_unpack
	S="${ORIGINAL_S}/mythtv"
	cd "${S}"
	epatch "${FILESDIR}/${PN}-0.21-ldconfig-sanxbox-fix.patch"
	epatch "${FILESDIR}/${PN}-ew-square-pixels.patch"
	epatch "${FILESDIR}/${PN}-ew-silencers.patch"
	epatch "${FILESDIR}/${PN}-ew-proxy.patch"
#	epatch "${FILESDIR}/${PN}_smoothsync-24fixes-p0.patch"
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

	hasq distcc "${FEATURES}" || myconf="${myconf} --disable-distcc"
	hasq ccache "${FEATURES}" || myconf="${myconf} --disable-ccache"

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
	dodir /var/log/mythtv
	fowners mythtv:mythtv /var/log/mythtv
	for i in mythbackend mythfrontend ; do
		newconfd "${FILESDIR}/${i}.conf" ${i}
		if use daemontools ; then
			dodir "/var/service/${i}"
			exeinto "/var/service/${i}"
			newexe "${FILESDIR}/${i}.run" run

			dodir "/var/service/${i}/log"
			exeinto "/var/service/${i}/log"
			newexe "${FILESDIR}/${i}.log.run" run

			dodir "/var/log/mythtv/${i}"
			fowners mythtv:mythtv "/var/log/mythtv/${i}"
		else
			newinitd "${FILESDIR}/${i}.rc" ${i}
			touch "${D}/var/log/mythtv/${i}.log"
			fowners mythtv:mythtv "/var/log/mythtv/${i}.log"
		fi
	done
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
