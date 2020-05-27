# Copyright (c) 2020 sakaki <sakaki@deciban.com>
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit acct-user

DESCRIPTION="A user for Jitsi Videobridge SFU"
ACCT_USER_ID=376
ACCT_USER_GROUPS=( jitsi )
ACCT_USER_HOME=/etc/jitsi/videobridge
ACCT_USER_HOME_PERMS=0750

acct-user_add_deps

