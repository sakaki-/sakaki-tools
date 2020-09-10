# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2
# Edited by Iade Gesso, PhD in 14th July 2020

EAPI=7

SRC_URI="https://github.com/Sabayon/genkernel-next/archive/v${PV}.tar.gz -> ${P}.tar.gz
         https://www.busybox.net/downloads/busybox-1.32.0.tar.bz2"
KEYWORDS="~alpha amd64 ~arm ~hppa ~ia64 ~ppc ~ppc64 x86"
inherit bash-completion-r1

DESCRIPTION="Gentoo automatic kernel building scripts, reloaded"
HOMEPAGE="https://github.com/Sabayon/genkernel-next/"

LICENSE="GPL-2"
SLOT="0"

IUSE="cryptsetup dmraid gpg iscsi mdadm plymouth selinux"
DOCS=( AUTHORS )

DEPEND="app-text/asciidoc
	sys-fs/e2fsprogs
	!sys-fs/eudev[-kmod,modutils]
	selinux? ( sys-libs/libselinux )"
RDEPEND="${DEPEND}
	!sys-kernel/genkernel
	cryptsetup? ( sys-fs/cryptsetup )
	dmraid? ( >=sys-fs/dmraid-1.0.0_rc16 )
	gpg? ( app-crypt/gnupg )
	iscsi? ( sys-block/open-iscsi )
	mdadm? ( sys-fs/mdadm )
	plymouth? ( sys-boot/plymouth )
	app-portage/portage-utils
	app-arch/cpio
	>=app-misc/pax-utils-0.6
	!<sys-apps/openrc-0.9.9
	sys-apps/util-linux
	sys-block/thin-provisioning-tools
	sys-fs/lvm2"

PATCHES=(
	"${FILESDIR}/genkernel-next-70_old_busybox.patch"
)

src_prepare() {
	default
	sed -i "/^GK_V=/ s:GK_V=.*:GK_V=${PV}:g" "${S}/genkernel" || \
		die "Could not setup release"

	# Get the real location of 'DISTDIR'
	portage_distdir=$(dirname `readlink "${DISTDIR}"/${P}.tar.gz`)

	# Replace the busybox path from the patch with the real 'DISTDIR' path
	# that is set in '/etc/portage/make.conf'
	sed -i 's:'"/usr/portage/distfiles"':'"${portage_distdir}"':g' "${S}/genkernel.conf" || \
		die "Failed to update busybox location"
}

src_install() {
	default

	doman "${S}"/genkernel.8

	newbashcomp "${S}"/genkernel.bash genkernel
}
