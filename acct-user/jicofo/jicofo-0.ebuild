# Copyright (c) 2020 sakaki <sakaki@deciban.com>
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit acct-user

DESCRIPTION="A user for JItsi COnference FOcus server"
ACCT_USER_ID=377
ACCT_USER_GROUPS=( jitsi )
ACCT_USER_HOME=/etc/jitsi/jicofo
ACCT_USER_HOME_PERMS=0750

acct-user_add_deps

