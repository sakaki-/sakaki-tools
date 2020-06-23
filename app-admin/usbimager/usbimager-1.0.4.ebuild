# Copyright 2020 sakaki <sakaki@deciban.com>
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit desktop xdg-utils unpacker

DESCRIPTION="Minimal GUI for writing compressed disk images to USB drives"
HOMEPAGE="https://gitlab.com/bztsrc/${PN}"
LICENSE="public-domain BSD BZIP2 MIT ZLIB"
SRC_URI="https://gitlab.com/bztsrc/${PN}/-/archive/${PV}/${P}.tar.bz2"

SLOT="0"
IUSE=""
RESTRICT="mirror"
KEYWORDS="~amd64 ~arm ~arm64"

RDEPEND="
	acct-group/disk
	x11-libs/libX11
"
DEPEND="${RDEPEND}
"

S="${WORKDIR}/${P}/src"

QA_PRESTRIPPED="usr/bin/${PN}"
QA_DESKTOP_FILE="usr/share/applications/${PN}.desktop"

src_compile() {
	emake GRP="" -j1
}

src_install() {
	dodir /usr/bin
	default
	local manpage="${D}/usr/share/man/man8/${PN}.8.gz"
	if [[ -f "${manpage}" ]]; then
		# prevent QA warnings about precompressed manpage
		cd ${D}/usr/share/man/man8
		unpack ./${PN}.8.gz
		rm -f ./${PN}.8.gz
	fi
}

pkg_postinst() {
	xdg_icon_cache_update
}

pkg_postrm() {
	xdg_icon_cache_update
}
