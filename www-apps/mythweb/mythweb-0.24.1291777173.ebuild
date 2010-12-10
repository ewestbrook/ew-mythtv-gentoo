# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/www-apps/mythweb/mythweb-0.23.1_p25396.ebuild,v 1.1 2010/07/27 03:14:08 cardoe Exp $

EAPI=2
inherit webapp depend.php versionator

######### ebuild editors take note #########
# $ git checkout branch
# $ HT=$(git log -n 1 --pretty="format:%H %ct") ; echo $HT
########## edit for new versions ###########
MYTHBRANCH="fixes" # select "fixes" for 0.24-fixes et al, or "master" for trunk
GITSTAMP="1291777173" # set to 9999999999 for latest version, integer timestamp for pinned
GITHASH="52cb8fb98f1aa209cfd2befa92a9cdd0b7841070" # for a numbered version
# GITHASH="" # leave empty for branch's latest version instead
############################################

HOMEPAGE="http://www.mythtv.org"
DESCRIPTION="PHP scripts intended to manage MythTV from a web browser."
LICENSE="GPL-2"
RESTRICT="nomirror"
IUSE=""
KEYWORDS="amd64 ppc x86"

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

[ "$EBSTAMP" == "$GITSTAMP" ] || die "In-ebuild timestamp integer doesn't filename's.  Edit ebuild."

EGIT_REPO_URI="git://github.com/${MY_PN}/${PN}"
EGIT_COMMIT=$([ "" == "${GITHASH}" ] && echo "${GITBRANCH}" || echo "${GITHASH}")
EGIT_BRANCH=$([ "fixes" == "${MYTHBRANCH}" ] && echo "fixes/${MYTHMAJOR}.${MYTHMINOR}" || echo "master")

inherit git

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