# Copyright 2020 sakaki (sakaki@deciban.com)
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit systemd

JMVER="$(ver_cut 4)"
DESCRIPTION="Webserver (nginx/apache) configurations for use with Jitsi Meet"
SRC_URI="https://github.com/jitsi/jitsi-meet/archive/stable/jitsi-meet_${JMVER}.tar.gz"
HOMEPAGE="https://jitsi.org/meet"
RESTRICT="mirror"

LICENSE="Apache-2.0"
SLOT="1.0"
KEYWORDS="~amd64 ~arm64"
IUSE="systemd"

DEPEND="
	>=dev-libs/openssl-1.0.2u
	~net-im/jitsi-meet-turnserver-${PV}
"
RDEPEND="
	${DEPEND}
	!systemd? ( virtual/cron )
	systemd? ( sys-apps/systemd )
	>=app-crypt/certbot-1.4.0
	|| (
		>=www-servers/nginx-1.18.0[ssl,\
nginx_modules_stream_map,\
nginx_modules_stream_ssl_preread]
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
	>=sys-process/lsof-4.91
"

S="${WORKDIR}/jitsi-meet-stable-jitsi-meet_${JMVER}"

PATCHES=(
	"${FILESDIR}/${P}_fixup_apache_config.patch"
	"${FILESDIR}/${P}_fixup_nginx_config.patch"
	"${FILESDIR}/${P}_fixup_nginx_example_config.patch"
)

src_prepare() {
	default
	sed -i "s#// anonymousdomain: 'guest.example.com',#anonymousdomain: 'guest.jitsi-meet.example.com',#g" \
		"${S}/config.js"
}

src_compile() {
	: # don't use default here
}

# Inspired with thanks from control flow in jitsi's equivalent deb
src_install() {
	keepdir /etc/jitsi/meet
	keepdir /etc/jitsi/certbot
	insinto /usr/share/${PN}
	doins config.js
	newins "${FILESDIR}/certbot.conf-1" "certbot.conf"
	doins doc/debian/jitsi-meet/jitsi-meet.example
	doins doc/debian/jitsi-meet/jitsi-meet.example-apache
	doins doc/example-config-files/nginx.conf.example
	dodoc doc/debian/jitsi-meet/README
	# provide a callback for use when master config changes
	insinto /etc/jitsi/config-updaters.d
	newins "${FILESDIR}/50-${PN}-7" "50-${PN}"
	# make sure we have directories to write into later
	keepdir /etc/{apache2,nginx}/sites-available
	keepdir /etc/nginx/sites-enabled
	# Gentoo doesn't use sites-enabled on apache2 by default
	keepdir /etc/apache2/vhosts.d
	# ensure that certbot has somewhere for challenges to go
	keepdir "/var/lib/${PN}/.well-known/acme-challenge"
	# certbot autorenewal services / scripts
	newsbin "${FILESDIR}/run-certbot.sh-5" "run-certbot.sh"
	newsbin "${FILESDIR}/reload-webservers.sh-4" "reload-webservers.sh"
	insinto /etc/logrotate.d
	newins "${FILESDIR}/certbot.logrotate-1" "certbot"
	systemd_newunit "${FILESDIR}/jitsi-certbot.service-1" "jitsi-certbot.service"
	systemd_newunit "${FILESDIR}/jitsi-certbot.timer-1" "jitsi-certbot.timer"
	if ! use systemd; then
		# no timers, do it the old school way for OpenRC
		# no /etc/init.d file required with this approach
		exeinto /etc/cron.daily
		newexe "${FILESDIR}/run-certbot-with-jitter-1" "run-certbot-with-jitter"
	fi
	# enable the timer, there are enough failsafes
	systemd_enable_service timers.target jitsi-certbot.timer
	ewarn "A daily certbot issue/renew-if-needed service has been enabled."
	ewarn "However, this will simply no-op each trigger, unless you elect to use"
	ewarn "a Let's Encrypt certificate when configuring your Jitsi server."
}

pkg_postinst() {
	if [[ -z "${REPLACING_VERSIONS}" ]]; then
		ewarn "${PN} has been installed, but not yet configured"
		ewarn "Manually set up your webserver configs in"
		ewarn "${EROOT%/}/etc/nginx/sites-{available,enabled} and"
		ewarn "${EROOT%/}/etc/apache2/{sites-available,vhosts.d} (as appropriate),"
		ewarn "create a key/crt pair if required, and set up a host"
		ewarn "config in ${EROOT%/}/etc/jitsi/meet/<host>-config.js."
		ewarn "Or, run:"
		ewarn "  emerge --config jitsi-meet-master-config"
		ewarn "for a prompt-driven process"
	fi
}
