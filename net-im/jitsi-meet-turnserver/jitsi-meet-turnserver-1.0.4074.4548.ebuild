# Copyright 2020 sakaki (sakaki@deciban.com)
# Distributed under the terms of the GNU General Public License v2

EAPI=7

JMVER="$(ver_cut 4)"
DESCRIPTION="Configures the net-im/coturn server to work with Jitsi Meet"
SRC_URI="https://github.com/jitsi/jitsi-meet/archive/stable/jitsi-meet_${JMVER}.tar.gz"
HOMEPAGE="https://jitsi.org/meet"
RESTRICT="mirror"

LICENSE="Apache-2.0"
SLOT="1.0"
KEYWORDS="~amd64 ~arm64"
IUSE="+port-443-mux"

DEPEND="
	>=dev-libs/openssl-1.0.2u
	>=net-im/coturn-4.5.1.1
	=net-im/jitsi-meet-prosody-${PV}
"
RDEPEND="
	${DEPEND}
	|| (
		>=www-servers/nginx-1.18.0[ssl,\
nginx_modules_stream_map,\
nginx_modules_stream_ssl_preread]
		!port-443-mux? (
			>=www-servers/apache-2.4.41[ssl]
		)
	)
"

S="${WORKDIR}/jitsi-meet-stable-jitsi-meet_${JMVER}"

PATCHES=(
)

src_compile() {
	: # don't use default here
}

# Inspired with thanks from control flow in jitsi's equivalent deb
src_install() {
	insinto /usr/share/${PN}
	# only save off the nginx module config if we're muxing on port 443
	# as specified by USE flag
	use port-443-mux && doins doc/debian/jitsi-meet/jitsi-meet.conf
	doins doc/debian/jitsi-meet-turn/coturn-certbot-deploy.sh
	doins doc/debian/jitsi-meet-turn/turnserver.conf
	dodoc doc/debian/jitsi-meet-turn/README
	# provide an updater callback, for use when master config changes
	insinto /etc/jitsi/config-updaters.d
	newins "${FILESDIR}/60-${PN}-1" "60-${PN}"
	# make sure we have directories to write into later
	# currently, only nginx can act as mux
	keepdir /etc/nginx/sites-available
	keepdir /etc/nginx/sites-enabled
	keepdir /etc/nginx/modules-available
	keepdir /etc/nginx/modules-enabled
}

pkg_postinst() {
	if [[ -z "${REPLACING_VERSIONS}" ]]; then
		ewarn "${PN} has been installed, but not yet configured"
		ewarn "Manually set up a config in ${EROOT%/}/etc/turnserver.conf"
		ewarn "or, run:"
		ewarn "  emerge --config jitsi-meet-master-config"
		ewarn "for a prompt-driven process"
	fi
}
