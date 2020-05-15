# Copyright (c) 2018 sakaki <sakaki@deciban.com>
# License: GPL v3+
# NO WARRANTY

EAPI=6
PYTHON_COMPAT=( python3_{4,5,6,7} )

inherit python-r1

DESCRIPTION="Tool for partial deblobbing of Intel ME/TXE firmware images"
HOMEPAGE="https://github.com/corna/me_cleaner"
SRC_URI=""
LICENSE="GPL-3+"
SLOT="0"
IUSE=""
RESTRICT="mirror"
KEYWORDS="~amd64 ~arm ~arm64"

SRC_URI="${HOMEPAGE}/archive/v${PV}.tar.gz -> ${P}.tar.gz"

RDEPEND=${PYTHON_DEPS}
REQUIRED_USE=${PYTHON_REQUIRED_USE}

src_install() {
	python_foreach_impl python_newscript "${PN}"{.py,}
	dodoc "README.md"
	doman "man/${PN}.1"
}

