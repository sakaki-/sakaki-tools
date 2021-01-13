# ebuild for showem (a simple emerge progress viewer)
# Copyright (c) 2015 sakaki <sakaki@deciban.com>
# License: GPL v2
# NO WARRANTY

EAPI=6

inherit eutils

DESCRIPTION="View output of a parallel emerge from a separate terminal"
BASE_SERVER_URI="https://github.com/GenPi64"
HOMEPAGE="${BASE_SERVER_URI}/${PN}"
SRC_URI="${BASE_SERVER_URI}/${PN}/archive/${PV}/${P}.tar.gz"

LICENSE="GPL-3+"
SLOT="0"
KEYWORDS="~amd64 ~x86 ~arm ~arm64 ~ppc"

RESTRICT="mirror"

DEPEND=""
RDEPEND="${DEPEND}
	>=sys-libs/ncurses-5.9-r2
	>=app-shells/bash-4.2"

# ebuild function overrides
src_prepare() {
	eapply_user
}
src_install() {
	dobin "${PN}"
	doman "${PN}.1"
}
