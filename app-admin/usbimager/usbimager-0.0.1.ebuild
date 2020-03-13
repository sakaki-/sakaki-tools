# Copyright 2020 sakaki <sakaki@deciban.com>
# Distributed under the terms of the GNU General Public License v2

EAPI=7
EGIT_REPO_URI="https://gitlab.com/bztsrc/${PN}.git"

inherit git-r3 desktop xdg-utils

DESCRIPTION="Minimal GUI for writing compressed disk images to USB drives"
HOMEPAGE="https://gitlab.com/bztsrc/${PN}"
SRC_URI=""
LICENSE="public-domain BSD BZIP2 MIT ZLIB"

SLOT="0"
IUSE=""
RESTRICT="mirror"
KEYWORDS="~amd64 ~arm ~arm64"

RDEPEND="
	x11-libs/libX11
"
DEPEND="${RDEPEND}
"

EGIT_BRANCH="master"
# fetch the branch at the specified commit, matches ebuild version
EGIT_COMMIT="20c3fbea2786f562d4e6a7e37ff91b8758f9e916"

S="${WORKDIR}/${P}/src"

QA_PRESTRIPPED="usr/bin/${PN}"
QA_DESKTOP_FILE="usr/share/applications/${PN}.desktop"

src_compile() {
	emake GRP="" -j1
}

src_install() {
	dobin ${PN}
	fowners :disk /usr/bin/${PN}
	fperms g+s /usr/bin/${PN}
	domenu misc/${PN}.desktop
	for ISIZE in 16 32 64 128; do
		newicon -s ${ISIZE} misc/icon${ISIZE}.png ${PN}.png
	done
	newdoc ../LICENSE ${PN}-LICENSE
	newdoc bzip2/LICENSE bzip2-LICENSE
	newdoc xz/COPYING xz-LICENSE
	newdoc zlib/LICENSE zlib-LICENSE
}

pkg_postinst() {
	xdg_icon_cache_update
}

pkg_postrm() {
	xdg_icon_cache_update
}
