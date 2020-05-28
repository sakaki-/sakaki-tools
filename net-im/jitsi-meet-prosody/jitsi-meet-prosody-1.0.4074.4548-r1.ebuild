# Copyright 2020 sakaki (sakaki@deciban.com)
# Distributed under the terms of the GNU General Public License v2

EAPI=7

JMVER="$(ver_cut 4)"
DESCRIPTION="Prosody configuration and plugins for use with Jitsi Meet"
SRC_URI="https://github.com/jitsi/jitsi-meet/archive/stable/jitsi-meet_${JMVER}.tar.gz"
HOMEPAGE="https://jitsi.org/meet"
RESTRICT="mirror"

LICENSE="Apache-2.0"
SLOT="1.0"
KEYWORDS="~amd64 ~arm64"
IUSE=""

DEPEND="
	>=app-misc/ca-certificates-20190110.3.43
	>=net-im/prosody-0.11.3
"
RDEPEND="
	${DEPEND}
	>=dev-lua/lua-zlib-1.1
"

S="${WORKDIR}/jitsi-meet-stable-jitsi-meet_${JMVER}"

PATCHES=(
	"${FILESDIR}/${P}_fixup_config.patch"
)

src_compile() {
	:
}

# Inspired with thanks from control flow in jitsi's equivalent deb
src_install() {
	insinto /usr/share/${PN}
	doins doc/debian/jitsi-meet-prosody/prosody.cfg.lua-jvb.example
	dodoc doc/debian/jitsi-meet-prosody/README
	insinto /usr/share/jitsi-meet
	doins -r resources/prosody-plugins

	# provide a callback to respond to changes in
	# the master config file
	insinto /etc/jitsi/config-updaters.d
	newins "${FILESDIR}/20-${PN}-2" "20-${PN}"

	# ensure we have config directories in prosody
	# to use
	keepdir "/etc/jabber/conf.d"
	keepdir "/etc/jabber/conf.avail"
}

pkg_postinst() {
	if [[ -z "${REPLACING_VERSIONS}" ]]; then

		ewarn "${PN} has been installed, but not yet configured"
		ewarn "Manually set up a config in /etc/jabber/conf.avail/"
		ewarn "and symlink it into /etc/jabber/conf.d (examples are"
		ewarn "available in ${EROOT%/}/usr/share/${PN}); or, run:"
		ewarn "  emerge --config jitsi-meet-master-config"
		ewarn "for a prompt-driven process"
	fi
	if ! grep -q '[^#]*Include "conf\.d/\*\.cfg\.lua"' "${EROOT%/}/etc/jabber/prosody.cfg.lua"; then
		elog "Making prosody read from /etc/jabber/conf.d/*.conf"
		echo -e "\nInclude \"conf.d/*.cfg.lua\"" >> \
			"${EROOT%/}/etc/jabber/prosody.cfg.lua"
	fi
	if grep -q '"prosody.log"' "${EROOT%/}/etc/jabber/prosody.cfg.lua"; then
		elog "Setting full path for log file"
		elog "  to \"/var/log/jabber/prosody.log\""
		sed -i 's#prosody.log#/var/log/jabber/prosody.log#g' \
			"${EROOT%/}/etc/jabber/prosody.cfg.lua"
	fi
	if grep -q '"prosody.err"' "${EROOT%/}/etc/jabber/prosody.cfg.lua"; then
		elog "Setting full path for error log file"
		elog "  to \"/var/log/jabber/prosody.err\""
		sed -i 's#prosody.err#/var/log/jabber/prosody.err#g' \
			"${EROOT%/}/etc/jabber/prosody.cfg.lua"
	fi
}

