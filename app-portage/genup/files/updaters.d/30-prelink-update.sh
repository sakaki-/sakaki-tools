#!/bin/bash
# Prelink all the binaries given by /etc/prelink.conf.
# Please make sure you have properly configured prelink before using this!
# See https://wiki.gentoo.org/wiki/Prelink
set -e
prelink --all --conserve-memory --random
