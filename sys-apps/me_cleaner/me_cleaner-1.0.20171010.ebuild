# Copyright (c) 2017 sakaki <sakaki@deciban.com>
# License: GPL v3+
# NO WARRANTY

EAPI=6
PYTHON_COMPAT=( python3_{4,5,6} )

inherit python-r1 git-r3

DESCRIPTION="Tool for partial deblobbing of Intel ME/TXE firmware images"
HOMEPAGE="https://github.com/corna/me_cleaner"
SRC_URI=""
LICENSE="GPL-3+"
SLOT="0"
IUSE=""
RESTRICT="mirror"
KEYWORDS="~amd64 ~arm ~arm64"

EGIT_REPO_URI="https://github.com/corna/me_cleaner"
EGIT_BRANCH="master"
# fetch the branch at the specified commit, matches ebuild date
EGIT_COMMIT="312ef02714dcab806c9d9bfee07f51002dc61e08"

RDEPEND=${PYTHON_DEPS}
REQUIRED_USE=${PYTHON_REQUIRED_USE}

src_install() {
	python_foreach_impl python_newscript "${PN}"{.py,}
}

