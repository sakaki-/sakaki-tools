# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="5"
inherit git-r3
DESCRIPTION="Tools for manipulating UEFI secure boot platforms"
HOMEPAGE="git://git.kernel.org/pub/scm/linux/kernel/git/jejb/efitools.git"
EGIT_REPO_URI="https://git.kernel.org/pub/scm/linux/kernel/git/jejb/${PN}.git"
EGIT_COMMIT="v${PV}"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

RDEPEND="dev-libs/openssl
	sys-apps/util-linux"
DEPEND="${RDEPEND}
	sys-apps/help2man
	>=sys-boot/gnu-efi-3.0u
	app-crypt/sbsigntool
	virtual/pkgconfig
	dev-perl/File-Slurp"

src_unpack() {
	git-r3_fetch
	git-r3_checkout
}

