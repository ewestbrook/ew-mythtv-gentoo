##########################################
# EW MythTV Gentoo Overlay Ebuilds       #
# github.com/ewestbrook/ew-mythtv-gentoo #
# E. Westbrook <ewmgoe@westbrook.com>    #
##########################################

EAPI=2
inherit webapp depend.php versionator

EGIT_PROJECT="mythweb"
DESCRIPTION="Web interface for MythTV"
inherit ew-mythtv-base

IUSE=""

RDEPEND="
	>=media-tv/mythtv-${PV}
	dev-lang/php[json,mysql,session,posix]
	|| ( <dev-lang/php-5.3[spl,pcre] >=dev-lang/php-5.3 )
	dev-perl/DBI
	dev-perl/DBD-mysql
	dev-perl/Net-UPnP"

DEPEND="${RDEPEND}
		app-arch/unzip"

need_httpd_cgi
need_php5_httpd

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
