#!/bin/sh
SCRIPT_DIR="$(cd "$(dirname "${0}")" && pwd)"
source "${SCRIPT_DIR}/install-config-base.sh"

# Base
DISTRIBUTION="ubuntu"
SUITE="mantic"
COMPONENTS=(main restricted universe multiverse)
VARIANT="minbase"

# Packages
MIRROR1="http://ftp.udx.icscoe.jp/Linux/ubuntu"
KEYS=( \
  'https://ftp-master.debian.org/keys/release-10.asc' \
  'https://ftp-master.debian.org/keys/archive-key-10.asc' \
  'https://ftp-master.debian.org/keys/archive-key-10-security.asc' \
  'https://ftp-master.debian.org/keys/release-11.asc' \
  'https://ftp-master.debian.org/keys/archive-key-11.asc' \
  'https://ftp-master.debian.org/keys/archive-key-11-security.asc' \
  'https://ftp-master.debian.org/keys/release-12.asc' \
  'https://ftp-master.debian.org/keys/archive-key-12.asc' \
  'https://ftp-master.debian.org/keys/archive-key-12-security.asc' \
  )
# ftp-master.debian.org Archive Signing Keys
# https://ftp-master.debian.org/keys.html

# Base and Image
INSTALLATION_PACKAGES_FOR_BASE+=(landscape-common)
INSTALLATION_PACKAGES_FOR_IMAGE=(linux-generic)

# Firmware
INSTALLATION_PACKAGES_FOR_FIRMWARE+=(linux-firmware fwupd-signed)

# systemd-timesyncd
FallbackNTP="ntp.ubuntu.com"

# Netplan
INSTALLATION_PACKAGES_FOR_NETPLAN=(network-manager netplan.io systemd-resolved)

# GRUB
INSTALLATION_PACKAGES_FOR_GRUB+=(shim-signed)
