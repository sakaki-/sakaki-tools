# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit eutils toolchain-funcs fdo-mime

DESCRIPTION="Program for improving image files made with a digital camera"
HOMEPAGE="https://www.kornelix.net/fotoxx/fotoxx.html"
SRC_URI="https://www.kornelix.net/downloads/tarballs/${P}.tar.gz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64 ~x86 ~arm64"
IUSE=""

RESTRICT="mirror"

DEPEND="
	x11-libs/gtk+:3
	media-libs/libpng
	media-libs/tiff
	media-libs/lcms:2
	media-libs/libraw
	media-libs/clutter
	media-libs/libchamplain[gtk]
	"
RDEPEND="${DEPEND}
	media-libs/exiftool
	media-gfx/ufraw[gtk]
	media-gfx/dcraw
	x11-misc/xdg-utils
	"

src_prepare() {
	epatch "${FILESDIR}"/${P}.patch
	epatch "${FILESDIR}"/${P}-champlain.patch
	epatch "${FILESDIR}"/${P}-debian-bug-916010.patch
	default
}

src_compile() {
	tc-export CXX
	emake
}

src_install() {
	# For the Help menu items to work, *.html must be in /usr/share/doc/${PF},
	# and README, changelog, translations, edit-menus, KB-shortcuts must not be compressed
	emake DESTDIR="${D}" install
	newmenu fotoxx.desktop ${PN}.desktop
	rm -f "${D}"/usr/share/doc/${PF}/*.man
	docompress -x /usr/share/doc
}

pkg_postinst() {
	fdo-mime_mime_database_update
	fdo-mime_desktop_database_update
	if use arm64; then
		# we also need a valid swrast dri link to work, but
		# eselect mesa doesn't manage this properly for
		# arm64 yet, so...
		if [[ ! -h "${ROOT%/}/usr/lib64/dri/swrast_dri.so" && -h "${ROOT%/}/usr/lib64/dri/swrastg_dri.so" ]]; then
			ewarn "Manually creating /usr/lib64/dri/swrast_dri.so symlink"
			cp -Pv "${ROOT%/}/usr/lib64/dri/"swrast{g,}_dri.so
		fi
	fi
}

pkg_postrm() {
	fdo-mime_desktop_database_update
	fdo-mime_mime_database_update
}
