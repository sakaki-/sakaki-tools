# Copyright 2020 sakaki (sakaki@deciban.com)
# Distributed under the terms of the GNU General Public License v2

EAPI=7
inherit unpacker

JMVER="$(ver_cut 4)"
DESCRIPTION="A WebRTC, JavaScript/WASM-based videoconferencing client"
SRC_URI="https://download.jitsi.org/jitsi/debian/${PN}_$(ver_cut 1-3)-1_all.deb"
HOMEPAGE="https://jitsi.org/meet"
RESTRICT="mirror"

LICENSE="Apache-2.0"
SLOT="1.0"
KEYWORDS="~amd64 ~arm64"
IUSE=""

DEPEND=""
RDEPEND="
	${DEPEND}
	|| (
		>=www-servers/nginx-1.18.0[ssl,nginx_modules_stream_map,nginx_modules_stream_ssl_preread]
		>=www-servers/apache-2.4.41[ssl,apache2_modules_rewrite,apache2_modules_headers,apache2_modules_proxy,apache2_modules_proxy_http,apache2_modules_include,apache2_modules_access_compat]
	)
"

S="${WORKDIR}"

src_unpack() {
	unpack_deb ${A}
}

src_prepare() {
	default
	rm -rf "${S}/usr/share/doc"
}

src_install() {
	insinto /
	doins -r usr
	# provide a callback to respond to master config changes
	insinto /etc/jitsi/config-updaters.d
	newins "${FILESDIR}/70-${PN}-1" "70-${PN}"
}
