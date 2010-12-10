##########################################
# EW MythTV Gentoo Overlay Ebuilds       #
# github.com/ewestbrook/ew-mythtv-gentoo #
# E. Westbrook <ewmgoe@westbrook.com>    #
##########################################

MY_PN="MythTV"
VC=( $(get_all_version_components ${PV}) )
MYTHMAJOR="${VC[0]}"
MYTHMINOR="${VC[2]}"
EBSTAMP="${VC[4]}"
GITBRIEF=${GITHASH:0:7}

IUSE="
  debug
  exif
  mmx
  mytharchive
  mythbrowser
  mythgallery
 -mythgame
  mythmusic
  mythnews
  mythmusic
  mythvideo
  mythweather
 -mythzoneminder
  mythnetvision
  opengl
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

[ "$EBSTAMP" == "$GITSTAMP" ] || die "In-ebuild timestamp integer doesn't filename's.  Edit ebuild."

EGIT_PROJECT="mythtv"
EGIT_REPO_URI="git://github.com/${MY_PN}/${EGIT_PROJECT}"
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
		$(use_enable mythvideo)
		$(use_enable mythweather)
		$(use_enable mythzoneminder)
		$(use_enable opengl)
		--libdir-name=$(get_libdir)
		--mandir=/usr/share/man
		--prefix=/usr
"

	einfo "Running ./configure ${myconf}"
	sh ./configure ${myconf} || die "configure died"
}

src_install() {
	einfo installing to INSTALL_ROOT: "${D}"
	make INSTALL_ROOT="${D}" install || die "install failed"
	# einstall INSTALL_ROOT="${D}" || die "install failed"
	fperms 0775 /usr/share/mythtv/mythvideo/scripts/jamu.py
}
