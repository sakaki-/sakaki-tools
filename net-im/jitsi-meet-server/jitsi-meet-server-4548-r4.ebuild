# Copyright (c) 2020 sakaki <sakaki@deciban.com>
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit systemd

DESCRIPTION="Jitsi Meet videoconferencing system, server set"
HOMEPAGE="https://jitsi.org/meet"
SRC_URI=""

LICENSE="GPL-3+"
SLOT="2.0"
KEYWORDS="~amd64 ~arm64"
IUSE="apache2 authbind +nginx"
REQUIRED_USE="
	^^ ( nginx apache2 )
"

# required by Portage, as we have no SRC_URI...
S="${WORKDIR}"

JMVER="4074"

DEPEND="
	>=app-shells/bash-5.0"

RDEPEND="
	${DEPEND}
	>=net-im/jitsi-meet-master-config-1
	~net-im/jitsi-meet-web-1.0.${JMVER}.${PV}
	~net-im/jitsi-meet-web-config-1.0.${JMVER}.${PV}
	~net-im/jicofo-1.0.567.${PV}
	~net-im/jitsi-videobridge-2.1.197.${PV}[authbind(-)?]
	~net-im/jitsi-meet-prosody-1.0.${JMVER}.${PV}
	>=app-crypt/certbot-1.4.0
	apache2? (
		~net-im/jitsi-meet-turnserver-1.0.${JMVER}.${PV}[-port-443-mux]
		>=www-servers/apache-2.4.41[ssl,\
apache2_modules_access_compat,\
apache2_modules_alias,\
apache2_modules_authz_core,\
apache2_modules_authz_host,\
apache2_modules_dir,\
apache2_modules_headers,\
apache2_modules_include,\
apache2_modules_mime,\
apache2_modules_proxy,\
apache2_modules_proxy_http,\
apache2_modules_rewrite,\
apache2_modules_socache_shmcb,\
apache2_modules_unixd]
	)
	nginx? (
		~net-im/jitsi-meet-turnserver-1.0.${JMVER}.${PV}[port-443-mux]
		>=www-servers/nginx-1.18.0[ssl,\
nginx_modules_stream_map,\
nginx_modules_stream_ssl_preread]
	)
"

src_install() {
	cp "${FILESDIR}/${PN}.service-1" "${T}/${PN}.service"
	cp "${FILESDIR}/${PN}.initd-3" "${T}/${PN}"
	if use apache2; then
		sed -i 's/nginx/apache2/g' "${T}/${PN}"{,.service}
	fi
	doinitd "${T}/${PN}"
	systemd_dounit "${T}/${PN}.service"
	newsbin "${FILESDIR}/${PN}-postcheck.sh-2" "${PN}-postcheck.sh"
}

pkg_postinst() {
	if [[ -z ${REPLACING_VERSIONS} ]]; then
		ewarn
		ewarn "****************************************************************"
		ewarn "Your Jitsi Meet server instance has been installed, however,"
		ewarn "you need to configure the various components before use."
		ewarn
		ewarn "Either do this manually case-by-case, OR simply issue:"
		ewarn "  emerge --config net-im/jitsi-meet-master-config"
		ewarn "and follow the prompts (much easier!)"
		ewarn
		ewarn "Once configured, you can start the server set by issuing:"
		ewarn "  rc-service ${PN} start"
		ewarn "(on OpenRC), or:"
		ewarn "  systmctl start ${PN}"
		ewarn "(on systemd)."
		ewarn
		ewarn "To have the Jitsi Meet server complex start automatically"
		ewarn "each boot, issue:"
		ewarn "  rc-update add ${PN} default"
		ewarn "(on OpenRC), or: "
		ewarn "  systemctl enable ${PN}"
		ewarn "(on systemd)."
		ewarn "****************************************************************"
		ewarn
	fi
}
