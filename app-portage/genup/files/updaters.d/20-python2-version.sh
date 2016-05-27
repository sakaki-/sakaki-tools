#!/bin/bash
# Update current version of Python 2 symlink to most recent 2.x installed.
# See https://github.com/sakaki-/genup/issues/5
set -e
eselect python update --python2
