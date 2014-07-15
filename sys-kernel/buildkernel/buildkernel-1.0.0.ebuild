# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5

inherit eutils

DESCRIPTION="Build secure boot EFI kernel with LUKS, LVM and plymouth"
BASE_SERVER_URI="https://github.com/sakaki-"
HOMEPAGE="${BASE_SERVER_URI}/${PN}"
SRC_URI="${BASE_SERVER_URI}/${PN}/archive/${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-3+"
SLOT="0"
KEYWORDS="~amd64"
IUSE="+plymouth"

RESTRICT="mirror"

DEPEND=">=sys-apps/gptfdisk-0.8.8
	>=sys-fs/cryptsetup-1.6.2
	>=app-shells/bash-4.2"
# TODO fix the gdm USE flag default for plymouth
RDEPEND="${DEPEND}
	>=sys-libs/ncurses-5.9-r2
	>=sys-kernel/gentoo-sources-3.12.20
	>=app-crypt/sbsigntool-0.6-r1
	plymouth? ( >=sys-boot/plymouth-0.8.8-r4[gdm,libkms,pango] )
	>=sys-kernel/genkernel-next-58[cryptsetup,gpg,plymouth?]
	=app-crypt/staticgpg-1.4.16
	>=sys-boot/efibootmgr-0.5.4-r1"

# ebuild function overrides
src_prepare() {
	# if the plymouth use flag not set, set script variable accordingly
	if ! use plymouth; then
	    elog "plymouth USE flag not selected - patching script accordingly."
		sed -i -e 's@USE_PLYMOUTH=true@USE_PLYMOUTH=false@g' "${S}/${PN}" || \
			die "Failed to patch script to reflect omitted plymouth USE flag."
	fi
	epatch_user
}
src_install() {
	dosbin "${PN}"
	insinto "/etc"
	doins "${PN}.conf"
	doman "${PN}.8"
	doman "${PN}.conf.5"
}
pkg_preinst() {
	# attempt to set the LUKS and EFI partition ids automatically
	# in the config file (in ${D}) if this can be done
	# unambiguously
	set_luks_partuuid_if_exactly_one_found
	set_efi_partuuid_if_exactly_one_found_on_usb
}
pkg_postinst() {
	elog "Be sure to check the CRYPTPARTUUID and EFIPARTUUID variables are"
	elog "set correctly in /etc/buildkernel.conf, and also ensure that you have an"
	elog "appropriate value for KEYMAP in this file, before running buildkernel."
}

# helper functions
set_luks_partuuid_if_exactly_one_found() {
	# checks all partitions for LUKS and, if exactly one is found, will set that
	# for the CRYPTPARTUUID in buildkernel.conf
	# if no candidate or multiple candidates found, print a warning
	local BKCONFPATH="$(echo "${D}/etc/buildkernel.conf" | sed 's#//*#/#g')"
	local REALBKCONFPATH="$(echo "${ROOT}/etc/buildkernel.conf" | sed 's#//*#/#g')"
	local PARTUUIDDEVDIR="$(echo "${ROOT}/dev/disk/by-partuuid" | sed 's#//*#/#g' )"
	if ! grep -q '^[[:space:]]*#[[:space:]]*CRYPTPARTUUID=' "${BKCONFPATH}"; then
		elog "CRYPTPARTUUID is already set in ${BKCONFPATH}, leaving as is"
		return
	fi
	elog "Attempting to find singleton LUKS partition for CRYPTPARTUUID..."
	local NEXTPART CANDIDATE=""
	for NEXTPART in "${PARTUUIDDEVDIR}"/*; do
		if cryptsetup isLuks "${NEXTPART}"; then
			if [ -z "${CANDIDATE}" ]; then
				CANDIDATE="${NEXTPART,,}"
			else
				ewarn " Multiple candidates for LUKS partition found!"
				ewarn " Please set CRYPTPARTUUID manually in ${REALBKCONFPATH}"
				return
			fi
		fi
	done
	if [ ! -z "${CANDIDATE}" ]; then
		elog " Found exactly one candidate: $(basename "${CANDIDATE}")"
		elog " (which is $(readlink --canonicalize "${CANDIDATE}"))"
		elog " Setting this for CRYPTPARTUUID in ${REALBKCONFPATH}"
		sed -i "s@^[[:space:]]*#[[:space:]]*CRYPTPARTUUID=.*@CRYPTPARTUUID=\"$(basename "${CANDIDATE}")\"@" "${BKCONFPATH}"
	else
		ewarn " No LUKS partition candidates found!"
		ewarn " Please set CRYPTPARTUUID manually in ${REALBKCONFPATH}"
	fi
}
set_efi_partuuid_if_exactly_one_found_on_usb() {
	# checks all partitions on USB devices only; if exactly one EFI system
	# partition is found, will set that for EFIPARTUUID in buildkernel.conf
	local BKCONFPATH="$(echo "${D}/etc/buildkernel.conf" | sed 's#//*#/#g')"
	local REALBKCONFPATH="$(echo "${ROOT}/etc/buildkernel.conf" | sed 's#//*#/#g')"
	local PARTUUIDDEVDIR="$(echo "${ROOT}/dev/disk/by-partuuid" | sed 's#//*#/#g' )"
	if ! grep -q '^[[:space:]]*#[[:space:]]*EFIPARTUUID=' "${BKCONFPATH}"; then
		ewarn "EFIPARTUUID is already set in ${BKCONFPATH}, leaving as is"
		return
	fi
	elog "Attempting to find singleton USB EFI system partition for EFIPARTUUID..."
	local NEXTPART CANDIDATE=""
	for NEXTPART in "${PARTUUIDDEVDIR}"/*; do
		if (udevadm info --query=all "${NEXTPART}" | grep -qi 'ID_BUS=[^=]*USB'); then
			local PARTNAME="$(readlink --canonicalize "${NEXTPART}")" # e.g. /dev/sda3
			local DEVNAME="${PARTNAME%%[[:digit:]]*}"			   # e.g. /dev/sda
			local PARTNUM="${PARTNAME##*[^[:digit:]]}"			  # e.g. 3
			# stat returns device type in hex only
			if (sgdisk --info "${PARTNUM}" "${DEVNAME}" | grep -qi 'EFI System'); then
				if [ -z "${CANDIDATE}" ]; then
					CANDIDATE="${NEXTPART,,}"
				else
					ewarn " Multiple candidates for EFI system partition found!"
					ewarn " Please set EFIPARTUUID manually in ${REALBKCONFPATH}"
					return
				fi
			fi
		fi
	done
	if [ ! -z "${CANDIDATE}" ]; then
		elog " Found exactly one candidate: $(basename "${CANDIDATE}")"
		elog " (which is $(readlink --canonicalize "${CANDIDATE}"))"
		elog " Setting this for EFIPARTUUID in ${REALBKCONFPATH}"
		sed -i "s@^[[:space:]]*#[[:space:]]*EFIPARTUUID=.*@EFIPARTUUID=\"$(basename "${CANDIDATE}")\"@" "${BKCONFPATH}"
	else
		ewarn " No USB EFI system partition candidates found!"
		ewarn " Please set EFIPARTUUID manually in ${REALBKCONFPATH}"
	fi
}
