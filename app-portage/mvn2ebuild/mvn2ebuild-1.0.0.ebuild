# Copyright (c) 2020 sakaki <sakaki@deciban.com>
# License: GPL v3+
# NO WARRANTY

EAPI=7

KEYWORDS="~amd64 ~arm64"

DESCRIPTION="Create a starter ebuild (using java-maven-pkg) for a Maven project"
HOMEPAGE="https://github.com/sakaki-/sakaki-tools"
SRC_URI=""
LICENSE="GPL-3+"
SLOT="0"
IUSE=""

RESTRICT="mirror"

DEPEND=""
RDEPEND="${DEPEND}
	>=app-shells/bash-4.4
	>=dev-vcs/git-2.23.3
	>=dev-java/maven-bin-3.6.2"

# required by Portage, as we have no SRC_URI...
S="${WORKDIR}"

src_install() {
	newbin "${FILESDIR}/${PN}-1" "${PN}"
	doman "${FILESDIR}/${PN}.1"
}
