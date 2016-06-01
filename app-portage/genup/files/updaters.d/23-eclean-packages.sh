#!/bin/bash
# Clean outdated binary packages from PKGDIR in Gentoo.
set -e
eclean --deep packages
