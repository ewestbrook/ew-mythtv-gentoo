##########################################
# EW MythTV Gentoo Overlay Ebuilds       #
# github.com/ewestbrook/ew-mythtv-gentoo #
# E. Westbrook <ewmgoe@westbrook.com>    #
##########################################

IUSE=""

RDEPEND="dev-lang/php[json,mysql,session,posix]
	|| ( <dev-lang/php-5.3[spl,pcre] >=dev-lang/php-5.3 )
	dev-perl/DBI
	dev-perl/DBD-mysql
	dev-perl/Net-UPnP"

DEPEND="${RDEPEND}
		app-arch/unzip"

need_httpd_cgi
need_php5_httpd

MY_PN="MythTV"
VC=( $(get_all_version_components ${PV}) )
MYTHMAJOR="${VC[0]}"
MYTHMINOR="${VC[2]}"
EBSTAMP="${VC[4]}"
GITBRIEF=${GITHASH:0:7}

EGIT_REPO_URI="git://github.com/${MY_PN}/${PN}"
EGIT_COMMIT=$([ "" == "${GITHASH}" ] && echo "${GITBRANCH}" || echo "${GITHASH}")
EGIT_BRANCH=$([ "fixes" == "${MYTHBRANCH}" ] && echo "fixes/${MYTHMAJOR}.${MYTHMINOR}" || echo "master")

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
  einfo GITHASH: $GITHASH
  einfo GITBRIEF: $GITBRIEF
  einfo SRC_URI: $SRC_URI
  einfo EGIT_REPO_URI: $EGIT_REPO_URI
  einfo EGIT_COMMIT: $EGIT_COMMIT
  einfo EGIT_BRANCH: $EGIT_BRANCH
  einfo ORIGINAL_S: $ORIGINAL_S
  einfo D: $D
fi

inherit git

src_unpack() {
	git_src_unpack
	cd "${S}"
	epatch "${FILESDIR}/ew-mythweb-lighty-docs.patch"
}

src_configure() {
	:
}

src_compile() {
	:
}

src_install() {
	webapp_src_preinst
	cd "${S}"
	dodoc README INSTALL
	dodir "${MY_HTDOCSDIR}/data"
	insinto "${MY_HTDOCSDIR}"
	doins -r [[:lower:]]*
	webapp_configfile "${MY_HTDOCSDIR}/mythweb.conf."{apache,lighttpd}
	webapp_serverowned "${MY_HTDOCSDIR}/data"
	webapp_postinst_txt en "${FILESDIR}/postinstall-en.txt"
	webapp_src_install
	fperms 755 "/usr/share/webapps/mythweb/${PV}/htdocs/mythweb.pl"
}
