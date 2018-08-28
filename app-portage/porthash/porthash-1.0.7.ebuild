# Copyright (c) 2017 sakaki <sakaki@deciban.com>
# License: GPL v3+
# NO WARRANTY

EAPI=5

KEYWORDS="~amd64 ~arm ~arm64 ~ppc"

DESCRIPTION="Compute, or verify, the signed hash of a Portage repo tree"
BASE_SERVER_URI="https://github.com/sakaki-"
HOMEPAGE="${BASE_SERVER_URI}/${PN}"
SRC_URI="${BASE_SERVER_URI}/${PN}/releases/download/${PV}/${P}.tar.gz"
LICENSE="GPL-3+"
SLOT="0"
IUSE="+add-pubkey"

RESTRICT="mirror"

DEPEND=""
RDEPEND="${DEPEND}
	>=app-crypt/gnupg-2.1.18
	>=app-shells/bash-4.2"

src_install() {
	dobin "${PN}"
	doman "${PN}.1"
	insinto "/usr/share/${PN}"
	newins "${FILESDIR}/sakaki-autosign-public-key.asc-1" sakaki-autosign-public-key.asc
}

pkg_postinst() {
	if use add-pubkey; then
		elog "Importing sakaki's autosigning public key into root keyring"
		gpg --homedir /root/.gnupg --import "/usr/share/${PN}/sakaki-autosign-public-key.asc" || die "Failed to import public key"
	fi
}

