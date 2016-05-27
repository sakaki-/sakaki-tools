#!/bin/bash
# Update current version of Python 3 symlink to most recent 3.x installed.
# See https://github.com/sakaki-/genup/issues/5
# Please be careful with this, as there are multiple SLOTs for Python 3 in
# Gentoo, and so you may well have e.g. 3.4 and 3.5 simultaneously installed,
# and end up with (via the following command) 3.5 as your default, when you
# might actually have preferred to keep the v3 default as 3.4.
set -e
eselect python update --python3
