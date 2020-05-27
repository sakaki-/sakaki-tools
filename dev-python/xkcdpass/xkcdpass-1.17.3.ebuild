# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

PYTHON_COMPAT=(python2_7 python3_{4,5,6,7})

inherit distutils-r1

DESCRIPTION="Generate secure multiword passwords/passphrases, inspired by XKCD 936"
HOMEPAGE="https://github.com/redacted/XKCD-password-generator"
SRC_URI="mirror://pypi/${PN:0:1}/${PN}/${P}.tar.gz"
SRC_URI="https://github.com/redacted/XKCD-password-generator/archive/${P}.tar.gz"

LICENSE="BSD CC-BY-3.0"
SLOT="0"
KEYWORDS="~amd64 ~arm64 ~x86"
IUSE=""
RESTRICT="mirror"

RDEPEND="
	${PYTHON_DEPS}
"
DEPEND="
	dev-python/setuptools[${PYTHON_USEDEP}]
	${RDEPEND}
"

S="${WORKDIR}/XKCD-password-generator-xkcdpass-${PV}"

DOCS="README.rst"

src_prepare() {
	default
	# cut down the word lists to just the basic
	# ones
	rm -f LICENSE-umich-spanishwords-00readme.txt
	rm -f contrib/office-safe.txt
	mv ${PN}/static/eff* ${T}/
	mv ${PN}/static/legacy ${T}/
	rm -f ${PN}/static/*
	mv ${T}/eff* ${PN}/static/
	mv ${T}/legacy ${PN}/static/
}

