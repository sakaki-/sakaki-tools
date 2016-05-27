#!/bin/bash
# Rebuild Haskell dependencies in Gentoo.
# See https://github.com/sakaki-/genup/issues/4
# Obviously, please make sure you have Haskell installed if using this!
set -e
haskell-updater
