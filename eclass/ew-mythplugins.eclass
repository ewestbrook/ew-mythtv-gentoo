##########################################
# EW MythTV Gentoo Overlay Ebuilds       #
# github.com/ewestbrook/ew-mythtv-gentoo #
# E. Westbrook <ewmgoe@westbrook.com>    #
##########################################

EAPI=2
inherit eutils versionator flag-o-matic multilib qt4 toolchain-funcs python

EGIT_PROJECT="mythtv"
DESCRIPTION="Plugin components for MythTV"
SLOT="0"
inherit ew-mythtv-base

IUSE="
  debug
  exif
  mmx
 +mytharchive
 +mythbrowser
 +mythgallery
 -mythgame
 +mythmusic
 +mythnetvision
 +mythnews
 +mythweather
 -mythzoneminder
  opengl
"
(("$MYTHMAJOR" == 0)) && (("$MYTHMINOR" < 25)) \
	&& IUSE="${IUSE}
 +mythvideo
"

RDEPEND="
  =media-tv/mythtv-${PV}
  app-cdr/dvd+rw-tools
  dev-lang/python
  media-video/dvdauthor
  media-video/ffmpeg
  media-video/mjpegtools[png]
  sys-apps/sed
  mythnetvision? ( dev-python/oauth dev-python/pycurl )
  mythweather? ( dev-perl/DateTime-Format-ISO8601 dev-perl/XML-XPath >dev-perl/DateManip-5.56 )
  dev-python/imaging
  dev-python/mysql-python
  media-video/transcode
  virtual/cdrtools
"
DEPEND="${RDEPEND}"

src_configure() {
	S="${ORIGINAL_S}/mythplugins"
	cd "${S}"
	local myconf="
		$(use_enable mytharchive)
		$(use_enable mythbrowser)
		$(use_enable mythgallery)
		$(use_enable mythgame)
		$(use_enable mythmusic)
		$(use_enable mythnetvision)
		$(use_enable mythnews)
		$(use_enable mythweather)
		$(use_enable mythzoneminder)
		$(use_enable opengl)
		--libdir-name=$(get_libdir)
		--mandir=/usr/share/man
		--prefix=/usr
"

	(("$MYTHMAJOR" == 0)) && (("$MYTHMINOR" < 25)) \
		&& myconf="${myconf} $(use_enable mythvideo)"

	einfo "Running ./configure ${myconf}"
	sh ./configure ${myconf} || die "configure died"
}

src_install() {
	einfo installing to INSTALL_ROOT: "${D}"
	make INSTALL_ROOT="${D}" install || die "install failed"
	# einstall INSTALL_ROOT="${D}" || die "install failed"
	fperms 0775 /usr/share/mythtv/mythvideo/scripts/jamu.py
}
