# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="5"

inherit eutils flag-o-matic toolchain-funcs

ECCVER="0.2.0"
ECCVER_GNUPG="1.4.9"
ECC_PATCH="${PN/staticgpg/gnupg}-${ECCVER_GNUPG}-ecc${ECCVER}.diff"
MY_P=${P/_/}
MY_P=${MY_P/staticgpg/gnupg}

DESCRIPTION="The GNU Privacy Guard (statically linked, no-pinentry version)"
HOMEPAGE="http://www.gnupg.org/"
SRC_URI="mirror://gnupg/gnupg/${P/staticgpg/gnupg}.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~x86 ~amd64"
IUSE=""

RDEPEND=""

DEPEND="dev-lang/perl"

S="${WORKDIR}/${MY_P}"

src_prepare() {
	# Install RU man page in right location
	sed -e "/^man_MANS =/s/ gpg\.ru\.1//" -i doc/Makefile.in || die "sed doc/Makefile.in failed"

	# bug#469388
	sed -i -e 's/--batch --dearmor/--homedir . --batch --dearmor/' checks/Makefile.in

	# Fix PIC definitions
	sed -i -e 's:PIC:__PIC__:' mpi/i386/mpih-{add,sub}1.S intl/relocatable.c \
		|| die "sed PIC failed"
	sed -i -e 's:if PIC:ifdef __PIC__:' mpi/sparc32v8/mpih-mul{1,2}.S || \
		die "sed PIC failed"
}

src_configure() {
	# Certain sparc32 machines seem to have trouble building correctly with
	# -mcpu enabled.  While this is not a gnupg problem, it is a temporary
	# fix until the gcc problem can be tracked down.
	if [ "${ARCH}" == "sparc" ] && [ "${PROFILE_ARCH}" == "sparc" ]; then
		filter-flags -mcpu=supersparc -mcpu=v8 -mcpu=v7
	fi

	# force static compilation
	append-ldflags -static
	# workaround gcc 10 feature
	# https://gcc.gnu.org/gcc-10/porting_to.html#common
	append-flags -fcommon

	econf \
		--docdir="${EPREFIX}/usr/share/doc/${PF}" \
		--enable-hkp \
		--enable-finger \
		--with-included-zlib \
		--without-capabilities \
		--enable-static-rnd=linux \
		--libexecdir="${EPREFIX}/usr/libexec" \
		--enable-noexecstack \
		CC_FOR_BUILD=$(tc-getBUILD_CC) \
		${myconf}
}

src_install() {
	# we only install the main binary, with new name staticgpg, into /usr/bin
	into /usr
	newbin "g10/gpg" "${PN}"
	# plus a short, redirecting manpage
	doman "${FILESDIR}/${PN}.1"
}

pkg_postinst() {
	ewarn "${PN} is only intended for use inside an initramfs."
	echo
	elog
	elog "See http://www.gentoo.org/doc/en/gnupg-user.xml for documentation on gnupg"
	elog
	elog "This is a special variant, which is compiled statically"
	elog "for use primarily in an initramfs context."
	elog "For more mainstream applications, use app-crypt/gnupg"
	elog "which can be installed in parallel with this package."
}
