# Copyright 2020 sakaki (sakaki@deciban.com)
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit estack

DESCRIPTION="Master configuration settings for Jitsi Meet server"
SRC_URI=""
HOMEPAGE="https://jitsi.org/meet"
RESTRICT="mirror"

LICENSE="Apache-2.0"
SLOT="1.0"
KEYWORDS="~amd64 ~arm64"
IUSE=""

DEPEND="
	>=app-misc/ca-certificates-20190110.3.43
	>=net-dns/bind-tools-9.14.8
	>=net-im/prosody-0.11.3
	>=net-misc/sipcalc-1.1.6
	>=dev-python/xkcdpass-1.17.3
	>=app-admin/apache-tools-2.4.41
"
RDEPEND="
	${DEPEND}
"

S="${WORKDIR}"

# Inspired with thanks from control flow in jitsi's equivalent deb
src_install() {
	keepdir /etc/jitsi/config-updaters.d
	insinto /etc/jitsi
	newins "${FILESDIR}/${PN}-1" "${PN}"
	fperms 750 "/etc/jitsi/${PN}"
	# keep a copy around elsewhere too
	insinto "/usr/share/${PN}"
	newins "${FILESDIR}/${PN}-1" "${PN}"
}

pkg_postinst() {
	if [[ -z "${REPLACING_VERSIONS}" ]]; then
		ewarn "To configure your Jitsi Meet services, via a"
		ewarn "prompt-driven process, simply run:"
		ewarn "  emerge --config ${PN}"
	fi
}

_gen_random() {
	# cryptographers, look away now
	tr -dc 'a-zA-Z0-9' </dev/urandom | head -c 16
}

_check-username() {
	local re='^[[:lower:]_][[:lower:][:digit:]_-]{2,15}$'
	(( ${#1} > 16 )) && return 1
	[[ "${1}" =~ ${re} ]]
}

_check-password() {
	local re='^[a-z]+(-[a-z]+)*$'
	(( ${#1} < 5 )) && return 1 # too short
	[[ "${1}" =~ ${re} ]]
}

_check-fqdn() {
	# basic check only
	[[ "${1}" == "localhost" ]] || \
		[[ $(grep -P '(?=^.{1,254}$)(^(?>(?!\d+\.)[a-zA-Z0-9_\-]{1,63}\.?)+(?:[a-zA-Z]{2,})$)' <<<"${1}" 2>/dev/null) ]]
}

_check-ip() {
	# match ip v4 or v6
	! [[ "$(sipcalc ${1} 2>&1)" =~ \[ERR ]]
}

_check-email() {
	# trivial check
	local re='^[^[:space:]@]+@[^[:space:]@]+$'
	[[ "${1}" =~ ${re} ]]
}

_check-max-memory() {
	local re="^([[:digit:]]+)([kKmMgG]?)$"
	[[ "${1}" =~ ${re} ]] || return 1
	local suffix="${BASH_REMATCH[2]}"
	local v="${BASH_REMATCH[1]}"
	case "${suffix}" in
		k|K) v=$((v*1024)) ;;
		m|M) v=$((v*1024*1024)) ;;
		g|G) v=$((v*1024*1024*1024)) ;;
		*) : ;;
	esac
	(( (v>=1024*1024*256) && (v%1024==0) ))
}

_ip_is_private() {
	# very basic check, not complete
	# assume valid IPv4 or IPv6 address to begin with
	[[ "${1}" == "localhost" ]] && return 0
	[[ "${1}" =~ ^10\. ]] && return 0
	[[ "${1}" =~ ^172\.([[:digit:]]+)\. ]] && ((BASH_REMATCH[1]>=16)) && \
		((BASH_REMATCH[1]<=31)) && return 0
	[[ "${1}" =~ ^192\.168\. ]] && return 0
	[[ "${1}" =~ ^fd  ]] && return 0 # RFC4193, L bit must be 1
	return 1
}

pkg_config() {
	local r
	rm -f "${EROOT%/}/etc/jitsi/.configured" # sentinel
	if [[ -s "${EROOT%/}/etc/jitsi/${PN}" ]]; then
		source "${EROOT%/}/etc/jitsi/${PN}"
	else
		ewarn "No current master configuration file found!"
	fi
	if [[ "${JMMC_BATCH_MODE}" =~ ^[Yy]$ ]]; then
		ewarn "As requested, using values from ${EROOT%/}/etc/jitsi/${PN}"
		ewarn "in batch mode, verbatim; no input will be requested"
		ewarn "and no fixup of values will be performed"
	else
		[[ -z "${JVB_HOSTNAME}" ]] && JVB_HOSTNAME="localhost"
		JVB_PRIOR_HOSTNAME="${JVB_HOSTNAME}"
		einfo "Preparing Jitsi Meet master configuration for a new instance."
		einfo
		einfo "NB: a single-box install is assumed; for more complex setups,"
		einfo "please configure manually."
		einfo
		einfo "When prompted for input, you can press Enter directly if you wish"
		einfo "to apply the [default value] for that field, otherwise,"
		einfo "type your desired value (without quotation marks), and press Enter."
		einfo
		einfo "NB: ALL passwords used by jitsi will be regenerated afresh"
		einfo "as part of this configuration run."
		einfo
		einfo "You can re-configure multiple times if desired."
		einfo
		einfo "**** Press Ctrl-c if you wish to abort ****"
		einfo
		while true; do
			einfo "Enter the server hostname (localhost or FQDN)."
			einfo "  (for example: \"jitsi.example.com\"; default is \"${JVB_HOSTNAME}\")"
			einfo "  Hint: you can check everything is working first, by specifying"
			einfo "  \"localhost\", and then run this configuration process again"
			einfo "  with the real FQDN, if desired." 
			einfon "Hostname [${JVB_HOSTNAME}]: "
			read r
			[[ "${r}" ]] || r="${JVB_HOSTNAME}"
			# check hostname (quick/crude)
			_check-fqdn "${r}" && break
			eerror "Illegal format for hostname; please try again"
		done
		JVB_HOSTNAME="${r}"
		JICOFO_AUTH_DOMAIN="auth.${JVB_HOSTNAME}"
		einfo "  OK, using \"${JVB_HOSTNAME}\" as (common) host,"
		einfo "  and \"${JICOFO_AUTH_DOMAIN}\" as jicofo auth domain"
		einfo
		if [[ "${JVB_HOSTNAME}" == "localhost" ]]; then
			JVB_EXTERNAL_IP="localhost"
			JVB_INTERNAL_IP="localhost"
			JVB_HOSTNAME_LOCALHOST_ALIAS="n"
			JVB_CONFORM_ETC_HOSTNAME="n"
		else
			# treat the external IP address somewhat differently
			# ignoring prior content on a change of FQDN
			if [[ "${JVB_HOSTNAME}" != "${JVB_PRIOR_HOSTNAME}" ]]; then
				JVB_EXTERNAL_IP=""
			fi
			if [[ -z "${JVB_EXTERNAL_IP}" ]]; then
				# for the default, we try to lookup JVB_HOSTNAME first in DNS,
				# and if that fails, try to obtain our external IP address,
				# and that fails (because e.g. offline), prompt with localhost
				JVB_EXTERNAL_IP="$(dig +short "${JVB_HOSTNAME}" @resolver1.opendns.com 2>/dev/null)"
				[[ -z "${JVB_EXTERNAL_IP}" ]] && JVB_EXTERNAL_IP="$(dig +short myip.opendns.com @resolver1.opendns.com 2>/dev/null)"
				[[ -z "${JVB_EXTERNAL_IP}" ]] && JVB_EXTERNAL_IP="localhost"
			fi
			while true; do
				einfo "Enter the _external_ IP address for the server."
				einfo "  (for example: \"82.221.139.201\"; default is \"${JVB_EXTERNAL_IP}\")"
				einfon "External IP address [${JVB_EXTERNAL_IP}]: "
				read r
				[[ "${r}" ]] || r="${JVB_EXTERNAL_IP}"
				# check ip address (quick/crude)
				_check-ip "${r}" && break
				eerror "Illegal format for IP address; please try again"
			done
			JVB_EXTERNAL_IP="${r}"
			einfo "  OK, using \"${JVB_EXTERNAL_IP}\" as external IP"
			einfo
			# start by assuming we're not NATted
			JVB_INTERNAL_IP="${JVB_EXTERNAL_IP}"
			while true; do
				einfo "Enter the _internal_ IP address for the server."
				einfo "  (for example: 192.168.1.50; default is \"${JVB_INTERNAL_IP}\")"
				einfo "  Should be the same as external IP, unless behind NAT."
				einfon "Internal IP address [${JVB_INTERNAL_IP}]: "
				read r
				[[ "${r}" ]] || r="${JVB_INTERNAL_IP}"
				# check ip address (quick/crude)
				_check-ip "${r}" && break
				eerror "Illegal format for IP address; please try again"
			done
			JVB_INTERNAL_IP="${r}"
			einfo "  OK, using \"${JVB_INTERNAL_IP}\" as internal IP"
			einfo
			if [[ "${JVB_INTERNAL_IP}" != "${JVB_EXTERNAL_IP}" ]]; then
				ewarn "  Assuming NAT: (ext) \"${JVB_EXTERNAL_IP}\" <-> \"${JVB_INTERNAL_IP}\" (int)"
				einfo
			fi

			einfon "Create a localhost alias for ${JVB_HOSTNAME}? (recommended) (y/n) [y]: "
			read r
			[[ -z ${r} ]] && r="y"
			if [[ "${r}" =~ ^[Yy]$ ]]; then
				einfo "  OK, localhost alias for ${JVB_HOSTNAME} requested"
				JVB_HOSTNAME_LOCALHOST_ALIAS="y"
			else
				einfo "  No localhost alias for ${JVB_HOSTNAME} requested"
				JVB_HOSTNAME_LOCALHOST_ALIAS="n"
			fi
			einfo
			einfon "Copy ${JVB_HOSTNAME} into \"/etc/hostname\"? (recommended) (y/n) [y]: "
			read r
			[[ -z ${r} ]] && r="y"
			if [[ "${r}" =~ ^[Yy]$ ]]; then
				einfo "  OK, will copy ${JVB_HOSTNAME} into \"/etc/hostname\""
				JVB_CONFORM_ETC_HOSTNAME="y"
			else
				einfo "  Leaving \"/etc/hostname\" unchanged"
				JVB_CONFORM_ETC_HOSTNAME="n"
			fi
			einfo
		fi
		JVB_MAX_MEMORY="1024m"
		while true; do
			einfo "Enter the RAM cap for the videobridge daemon, in bytes."
			einfo "  Technically, the max size of its Java memory allocation pool."
			einfo "  Must be a multiple of 1024, and >=256m; suffixes"
			einfo "  k (or K), m (or M) and g (or G) are permitted."
			einfo "  (for example \"2g\", default is \"${JVB_MAX_MEMORY}\")"
			einfon "Max videobridge daemon RAM [${JVB_MAX_MEMORY}]: "
			read r
			[[ "${r}" ]] || r="${JVB_MAX_MEMORY}"
			# check RAM
			_check-max-memory "${r}" && break
			eerror "Illegal format for RAM size; please try again"
		done
		JVB_MAX_MEMORY="${r}"
		einfo "  OK, using \"${JVB_MAX_MEMORY}\" as videobridge daemon RAM cap"
		einfo
		[[ -z "${JICOFO_AUTH_USER}" ]] && JICOFO_AUTH_USER="focus"
		[[ -z "${JICOFO_CONVENE_USER}" ]] && JICOFO_CONVENE_USER="admin"
		[[ -z "${JVB_AUTH_USER}" ]] && JVB_AUTH_USER="jvb"
		while true; do
			einfo "Enter the XMPP user who is allowed to _start_ new meetings."
			einfo "  NB: anyone can _join_ a meeting via URL once started, although"
			einfo "  access to any room can also be password restricted by its"
			einfo "  creator, via the web interface, if desired."
			einfo "  (default is \"${JICOFO_CONVENE_USER}\")"
			einfon "Username [${JICOFO_CONVENE_USER}]: "
			read r
			[[ "${r}" ]] || r="${JICOFO_CONVENE_USER}"
			# check username (quick/crude)
			[[ "${JICOFO_CONVENE_USER}" != "${JICOFO_AUTH_USER}" ]] && \
			[[ "${JICOFO_CONVENE_USER}" != "${JVB_AUTH_USER}" ]] && _check-username "${r}" && break
			eerror "Illegal format for username; please try again"
		done
		JICOFO_CONVENE_USER="${r}"
		einfo "  OK, using \"${JICOFO_CONVENE_USER}\" as permitted convener"
		einfo

		# forcibly reset this, use XKCD 936-style passwords
		JICOFO_CONVENE_PASSWORD="$(xkcdpass -d'-' -n 3)"
		while true; do
			einfo "Enter the password for user \"${JICOFO_CONVENE_USER}\"."
			einfo "  Only lowercase letters and hyphen are permitted, 5 chars minimum."
			einfo "  (default is \"${JICOFO_CONVENE_PASSWORD}\")"
			einfon "Password [${JICOFO_CONVENE_PASSWORD}]: "
			read r
			[[ "${r}" ]] || r="${JICOFO_CONVENE_PASSWORD}"
			# check password (quick/crude)
			_check-password "${r}" && break
			eerror "Illegal format for password; please try again"
		done
		JICOFO_CONVENE_PASSWORD="${r}"
		einfo "  OK, using \"${JICOFO_CONVENE_PASSWORD}\" as password for \"${JICOFO_CONVENE_USER}\""
		einfo "  Please don't forget the above password and username!"
		einfo "  You won't be able to start new meetings without them!"
		einfo "  (NB, you _don't_ need to add any domain suffix to the"
		einfo "  \"${JICOFO_CONVENE_USER}\" username when entering it in"
		einfo "  the Jitsi Meet web interface.)"

		LE_HOSTNAME=""
		LE_ENABLE_AUTO="n"
		LE_EMAIL=""
		LE_WEBROOT=""

		einfo
		einfo "Do you wish to supply your own key/crt pair for the"
		einfo "Jitsi Meet webserver?"

		if [[ "${JVB_HOSTNAME}" == "localhost" ]] || _ip_is_private "${JVB_EXTERNAL_IP}"; then
			einfo "  (It isn't possible to use Let's Encrypt for \"${JVB_HOSTNAME}\" (private IP))"
			einfo "  NB: if you elect NOT to supply a pre-existing pair,"
			einfo "  a self-signed pair will automatically be generated for you."
		else
			einfo "  NB: if you elect NOT to supply a pre-existing pair,"
			einfo "  you'll be further prompted whether to turn on"
			einfo "  free, automatic certificate generation and renewal"
			einfo "  via the Let's Encrypt service for this domain, or"
			einfo "  to have a self-signed pair generated locally for you."
		fi
		einfo
		einfon "Supply pre-existing key/crt pair for ${JVB_HOSTNAME}? (y/n) [n]: "
		read r
		[[ -z ${r} ]] && r="n"
		if [[ "${r}" =~ ^[Yy]$ ]]; then
			einfo "  OK, you wish to supply your own key/crt pair"
			JM_SUPPLY_OWN_CRT="y"
			# we'll check the files specified exist, but not create
			# certificates etc here - that's the job of the plugin
			[[ -z "${JM_WEB_CERT_KEY}" ]] && JM_WEB_CERT_KEY="/etc/ssl/${JVB_HOSTNAME}.key"
			while true; do
				einfo "Enter the full path to the SSL private key."
				einfo "  (default is \"${JM_WEB_CERT_KEY}\")"
				einfon "Path [${JM_WEB_CERT_KEY}]: "
				read r
				[[ "${r}" ]] || r="${JM_WEB_CERT_KEY}"
				# check if exists; paths are absolute (relative to prefix)
				[[ -e "${EROOT%/}${r}" ]] && break
				eerror "No such file; please try again"
			done
			JM_WEB_CERT_KEY="${r}"
			[[ -z "${JM_WEB_CERT_CRT}" ]] && JM_WEB_CERT_CRT="/etc/ssl/${JVB_HOSTNAME}.crt"
			while true; do
				einfo "Enter the full path to the SSL certificate."
				einfo "  (default is \"${JM_WEB_CERT_CRT}\")"
				einfon "Path [${JM_WEB_CERT_CRT}]: "
				read r
				[[ "${r}" ]] || r="${JM_WEB_CERT_CRT}"
				# check if exists
				[[ -e "${EROOT%/}${r}" ]] && break
				eerror "No such file; please try again"
			done
			JM_WEB_CERT_CRT="${r}"
		else
			if [[ "${JVB_HOSTNAME}" == "localhost" ]] || _ip_is_private "${JVB_EXTERNAL_IP}"; then
				einfo "  OK, a self-signed key/crt pair will be generated for you"
				einfo
				JM_SUPPLY_OWN_CRT="n"
				JM_WEB_CERT_KEY="/etc/jitsi/meet/${JVB_HOSTNAME}.key"
				JM_WEB_CERT_CRT="/etc/jitsi/meet/${JVB_HOSTNAME}.crt"
			else
				einfo "  OK, you do not wish to supply a pre-existing key/crt pair."
				einfo
				einfo "In that case, would you like to turn on automatic TLS certificate"
				einfo "generation for this domain, via Let's Encrypt? (free, recommended)"
				einfo "  NB: if you do, you'll need to ensure that at least an A record"
				einfo "  for \"${JVB_HOSTNAME}\" exists in public DNS, pointing to"
				einfo "  \"${JVB_EXTERNAL_IP}\"; you'll also be deemed to have agreed"
				einfo "  to Let's Encrypt's terms of service, which may be viewed at:"
				einfo "    https://letsencrypt.org/repository/"
				einfo
				einfo "  On the other hand, if you elect NOT to use Let's Encrypt, a"
				einfo "  self-signed certificate will automatically be generated locally"
				einfo "  for you instead."
				einfo
				einfon "Activate Let's Encrypt for ${JVB_HOSTNAME}? (y/n) [y]: "
				read r
				[[ -z ${r} ]] && r="y"
				if [[ "${r}" =~ ^[Yy]$ ]]; then
					einfo "  OK, you wish to activate Let's Encrypt for \"${JVB_HOSTNAME}\""
					einfo "  A self-signed key/crt pair will be still be created initially,"
					einfo "  but will be replaced by the Let's Encrypt pair once the"
					einfo "  webserver is brought online (and the automated domain-ownership"
					einfo "  challenge passed)."
					einfo
					LE_HOSTNAME="${JVB_HOSTNAME}"
					LE_ENABLE_AUTO="y"
					LE_WEBROOT="/var/lib/jitsi-meet-web-config"
					JM_SUPPLY_OWN_CRT="n"
					JM_WEB_CERT_KEY="/etc/jitsi/meet/${JVB_HOSTNAME}.key"
					JM_WEB_CERT_CRT="/etc/jitsi/meet/${JVB_HOSTNAME}.crt"
					# these (created) files in /etc/jitsi/meet will become
					# symlinks to /etc/letsencrypt/live/${LE_HOSTNAME}/privkey.pem
					# and /etc/letsencrypt/live/${LE_HOSTNAME}/fullchain.pem once
					# the initial certificate is issued

					[[ -z "${LE_EMAIL}" ]] && LE_EMAIL="webmaster@${LE_HOSTNAME}"
					while true; do
						einfo "Enter the contact email to be used for Let's Encrypt signup."
						einfo "  This will be used for automated expiry notices and"
						einfo "  similar purposes only (it will not be released to the EFF,"
						einfo "  and no 'validation' email will be sent). The email address"
						einfo "  need not belong to the same domain as your Jitsi host." 
						einfo "  (default is \"${LE_EMAIL}\")"
						einfon "Email address [${LE_EMAIL}]: "
						read r
						[[ "${r}" ]] || r="${LE_EMAIL}"
						# check email (quick/crude)
						_check-email "${r}" && break
						eerror "Illegal format for email address; please try again"
					done
					LE_EMAIL="${r}"
					einfo "  OK, using \"${LE_EMAIL}\" as your Let's Encrypt email address"
					einfo
				else
					einfo "  OK, a self-signed key/crt pair will be generated for you"
					einfo
					JM_SUPPLY_OWN_CRT="n"
					JM_WEB_CERT_KEY="/etc/jitsi/meet/${JVB_HOSTNAME}.key"
					JM_WEB_CERT_CRT="/etc/jitsi/meet/${JVB_HOSTNAME}.crt"
				fi

			fi
		fi
		einfo "  SSL key path: \"${JM_WEB_CERT_KEY}\""
		einfo "  SSL crt path: \"${JM_WEB_CERT_CRT}\""

		einfo
		einfo "Automatically creating new secrets:"
		JVB_AUTH_PASSWORD="$(_gen_random)"
		einfo "  Created a new prosody password for \"${JVB_AUTH_USER}\"        (\"${JVB_AUTH_PASSWORD}\")"
		JICOFO_AUTH_PASSWORD="$(_gen_random)"
		einfo "  Created a new prosody password for \"${JICOFO_AUTH_USER}\"      (\"${JICOFO_AUTH_PASSWORD}\")"
		JVB_SECRET="$(_gen_random)"
		einfo "  Created a new VideoBridge XMPP component secret (\"${JVB_SECRET}\")"
		JICOFO_SECRET="$(_gen_random)"
		einfo "  Created a new jicofo XMPP component secret      (\"${JICOFO_SECRET}\")"
		TURN_SECRET="$(_gen_random)"
		einfo "  Created a new turnserver connection secret      (\"${TURN_SECRET}\")"
		MUC_UUID="$(uuidgen)"
		einfo "  Created MUC UUID: ${MUC_UUID}"
		einfo
		einfo "Automatically setting certain values:"
		JVB_HOST="localhost"
		JVB_PORT="5347"
		einfo "  XMPP server (prosody) host: ${JVB_HOST}"
		einfo "  XMPP server (prosody) port: ${JVB_PORT}"
		einfo
		einfon "Configuration complete: write it? (y/n) [y]: "
		read r
		[[ -z ${r} ]] && r="y"
		if ! [[ "${r}" =~ ^[Yy]$ ]]; then
			ewarn "As requested, your new configuration has NOT been written"
			return
		fi
		local JM_WEB_CERT_KEY_ESC="${JM_WEB_CERT_KEY//\//\\/}"
		local JM_WEB_CERT_CRT_ESC="${JM_WEB_CERT_CRT//\//\\/}"
		sed -e \
's/^JVB_HOSTNAME=.*"/JVB_HOSTNAME="'"${JVB_HOSTNAME}"'"/ ; '\
's/^JVB_CONFORM_ETC_HOSTNAME=.*"/JVB_CONFORM_ETC_HOSTNAME="'"${JVB_CONFORM_ETC_HOSTNAME}"'"/ ; '\
's/^JVB_HOST=.*"/JVB_HOST="'"${JVB_HOST}"'"/ ; '\
's/^JVB_PORT=.*"/JVB_PORT="'"${JVB_PORT}"'"/ ; '\
's/^JVB_EXTERNAL_IP=.*"/JVB_EXTERNAL_IP="'"${JVB_EXTERNAL_IP}"'"/ ; '\
's/^JVB_INTERNAL_IP=.*"/JVB_INTERNAL_IP="'"${JVB_INTERNAL_IP}"'"/ ; '\
's/^JVB_HOSTNAME_LOCALHOST_ALIAS=.*"/JVB_HOSTNAME_LOCALHOST_ALIAS="'"${JVB_HOSTNAME_LOCALHOST_ALIAS}"'"/ ; '\
's/^JVB_MAX_MEMORY=.*"/JVB_MAX_MEMORY="'"${JVB_MAX_MEMORY}"'"/ ; '\
's/^JM_SUPPLY_OWN_CRT=.*"/JM_SUPPLY_OWN_CRT="'"${JM_SUPPLY_OWN_CRT}"'"/ ; '\
's/^JM_WEB_CERT_KEY=.*"/JM_WEB_CERT_KEY="'"${JM_WEB_CERT_KEY_ESC}"'"/ ; '\
's/^JM_WEB_CERT_CRT=.*"/JM_WEB_CERT_CRT="'"${JM_WEB_CERT_CRT_ESC}"'"/ ; '\
's/^JICOFO_AUTH_USER=.*"/JICOFO_AUTH_USER="'"${JICOFO_AUTH_USER}"'"/ ; '\
's/^JICOFO_AUTH_DOMAIN=.*"/JICOFO_AUTH_DOMAIN="'"${JICOFO_AUTH_DOMAIN}"'"/ ; '\
's/^JICOFO_AUTH_PASSWORD=.*"/JICOFO_AUTH_PASSWORD="'"${JICOFO_AUTH_PASSWORD}"'"/ ; '\
's/^JVB_AUTH_USER=.*"/JVB_AUTH_USER="'"${JVB_AUTH_USER}"'"/ ; '\
's/^JVB_AUTH_PASSWORD=.*"/JVB_AUTH_PASSWORD="'"${JVB_AUTH_PASSWORD}"'"/ ; '\
's/^JICOFO_CONVENE_USER=.*"/JICOFO_CONVENE_USER="'"${JICOFO_CONVENE_USER}"'"/ ; '\
's/^JICOFO_CONVENE_PASSWORD=.*"/JICOFO_CONVENE_PASSWORD="'"${JICOFO_CONVENE_PASSWORD}"'"/ ; '\
's/^JVB_SECRET=.*"/JVB_SECRET="'"${JVB_SECRET}"'"/ ; '\
's/^JICOFO_SECRET=.*"/JICOFO_SECRET="'"${JICOFO_SECRET}"'"/ ; '\
's/^TURN_SECRET=.*"/TURN_SECRET="'"${TURN_SECRET}"'"/ ; '\
's/^MUC_UUID=.*"/MUC_UUID="'"${MUC_UUID}"'"/ ; '\
's/^LE_ENABLE_AUTO=.*"/LE_ENABLE_AUTO="'"${LE_ENABLE_AUTO}"'"/ ; '\
's/^LE_HOSTNAME=.*"/LE_HOSTNAME="'"${LE_HOSTNAME}"'"/ ; '\
's/^LE_EMAIL=.*"/LE_EMAIL="'"${LE_EMAIL}"'"/ ; '\
's#^LE_WEBROOT=.*"#LE_WEBROOT="'"${LE_WEBROOT}"'"# ' \
			< "${EROOT%/}/usr/share/${PN}/${PN}" >"${EROOT%/}/etc/jitsi/${PN}"
		chmod 640 "${EROOT%/}/etc/jitsi/${PN}"
		einfo "New configuration written to ${EROOT%/}/etc/jitsi/${PN}"
		einfo
		einfon "Build component configurations from this? (y/n) [y]: "
		read r
		[[ -z ${r} ]] && r="y"
		if ! [[ "${r}" =~ ^[Yy]$ ]]; then
			ewarn "As requested, no component re-configurations have been triggered"
			return
		fi
	fi
	eshopts_push -s nullglob
	local c
	local REBOOT_REQUIRED=0
	for c in ${EROOT%/}/etc/jitsi/config-updaters.d/*; do
		if [[ -s "${c}" ]]; then
			einfo "----------------------------------------------------------------------"
			einfo "Running ${c}"
			einfo "----------------------------------------------------------------------"
			source "${c}" || die "Error running updater!"
		fi
	done
	eshopts_pop
	einfo
	ewarn "======================================================================"
	ewarn "Your new configuration has been written, but you now need to"
	if ((REBOOT_REQUIRED==1)); then
		ewarn "restart your system, and once that completes"
	fi
	ewarn "(re)start the various servers (jitsi-videobridge, turnserver/"
	ewarn "coturn, jicofo, prosody and nginx (or apache2), at minimum)"
	ewarn "to have it take effect."
	if ((REBOOT_REQUIRED==0)); then
		ewarn "You can do this conveniently by issuing:"
	else
		ewarn "You can do this latter step conveniently by issuing:"
	fi
	ewarn "  rc-service jitsi-meet-server restart    # on OpenRC, or"
	ewarn "  systemctl restart jitsi-meet-server     # on systemd"
	ewarn
	ewarn "To start automatically each boot, issue:"
	ewarn "  rc-update add jitsi-meet-server default # on OpenRC, or"
	ewarn "  systemctl enable jitsi-meet-server      # on systemd"
	ewarn "======================================================================"
	ewarn "Don't forget the new meeting convener credentials! They are:"
	ewarn "  Username: \"${JICOFO_CONVENE_USER}\""
	ewarn "  Password: \"${JICOFO_CONVENE_PASSWORD}\""
	ewarn "  (any dashes in the above password are hyphens, not spaces)"
	ewarn "======================================================================"
	ewarn "NB: you can run this configuration step again in the future, if"
	ewarn "desired, by issuing:"
	ewarn "  emerge --config net-im/jitsi-meet-master-config"
	ewarn "======================================================================"
	touch "${EROOT%/}/etc/jitsi/.configured" # sentinel
}

