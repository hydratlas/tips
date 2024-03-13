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
ARCHIVE_KEYRING_PACKAGE="ubuntu-keyring"
ARCHIVE_KEYRING="/usr/share/keyrings/ubuntu-archive-keyring.gpg"

# Base and Image
INSTALLATION_PACKAGES_FOR_BASE+=(landscape-common)
INSTALLATION_PACKAGES_FOR_IMAGE=(linux-generic)

# Firmware
INSTALLATION_PACKAGES_FOR_FIRMWARE+=(linux-firmware fwupd-signed)

# systemd-timesyncd
FallbackNTP="ntp.ubuntu.com"

# Netplan
INSTALLATION_PACKAGES_FOR_NETPLAN=(network-manager netplan.io)

# GRUB
INSTALLATION_PACKAGES_FOR_GRUB+=(shim-signed)
