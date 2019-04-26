# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=5

inherit eutils

DESCRIPTION="Update Portage tree, all installed packages, and kernel"
BASE_SERVER_URI="https://github.com/sakaki-"
HOMEPAGE="${BASE_SERVER_URI}/${PN}"
SRC_URI="${BASE_SERVER_URI}/${PN}/releases/download/${PV}/${P}.tar.gz"

LICENSE="GPL-3+"
SLOT="0"
KEYWORDS="~amd64 ~arm ~arm64 ~ppc"
IUSE="+buildkernel emtee nocache"

RESTRICT="mirror"

DEPEND=""
RDEPEND="${DEPEND}
	nocache? ( >=sys-fs/nocache-1.1 )
	emtee? ( >=app-portage/emtee-1.0.2 )
	>=sys-libs/ncurses-5.9-r2
	>=app-portage/eix-0.29.3
	>=app-admin/perl-cleaner-2.7
	>=app-portage/gentoolkit-0.3.0.8-r2
	amd64? ( buildkernel? ( >=sys-kernel/buildkernel-1.0.13 ) )
	>=app-shells/bash-4.2"

# ebuild function overrides
src_prepare() {
	# if the buildkernel use flag not set, set script variable accordingly
	if ! use buildkernel; then
		elog "buildkernel USE flag not selected - patching script accordingly."
		sed -i -e 's@USE_BUILDKERNEL=true@USE_BUILDKERNEL=false@g' "${S}/${PN}" || \
			die "Failed to patch script to reflect omitted buildkernel USE flag."
	elif use arm || use ppc; then
		ewarn "buildkernel USE flag not supported on this architecture"
		ewarn "please consider re-emerging with it turned off;"
		ewarn "you may still use genup, but must manually specify the"
		ewarn "--no-kernel-upgrade option each time, unless you do"
		ewarn "(otherwise, genup will fail)"
	fi
	if use emtee; then
		elog "emtee USE flag selected - patching script accordingly."
		sed -i -e 's@USE_EMTEE=false@USE_EMTEE=true@g' "${S}/${PN}" || \
			die "Failed to patch script to reflect emtee USE flag."
	fi
	if use nocache; then
		elog "nocache USE flag selected - patching script accordingly."
		sed -i -e 's@USE_NOCACHE=false@USE_NOCACHE=true@g' "${S}/${PN}" || \
			die "Failed to patch script to reflect nocache USE flag."
	fi
	epatch_user
}
src_install() {
	dosbin "${PN}"
	doman "${PN}.8"
	elog "Ensuring eix syncs overlays and updates the metadata cache, and that"
	elog "eix-update uses that cache, per:"
	elog "https://wiki.gentoo.org/wiki/Overlay#eix_integration"
	insinto "/etc"
	doins "${FILESDIR}/eix-sync.conf"
	insinto "/etc/eixrc"
	doins "${FILESDIR}/01-cache"
	dodir "/etc/genup/updaters.d/examples"
	insinto "/etc/genup/updaters.d"
	newins "${FILESDIR}/updaters-README" README
	exeinto "/etc/genup/updaters.d/examples"
	doexe "${FILESDIR}/updaters.d/20-python2-version.sh"
	doexe "${FILESDIR}/updaters.d/21-python3-version.sh"
	doexe "${FILESDIR}/updaters.d/22-haskell-updater.sh"
	doexe "${FILESDIR}/updaters.d/23-eclean-packages.sh"
	insinto "/etc/genup/updaters.d/examples"
	doins "${FILESDIR}/updaters.d/README"
}
